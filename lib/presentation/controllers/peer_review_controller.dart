import 'package:get/get.dart';
import '../../domain/models/assessment.dart';
import '../../domain/models/course_activity.dart';
import '../../domain/models/peer_review_summaries.dart';
import '../../domain/repositories/assessment_repository.dart';
import '../../domain/repositories/membership_repository.dart';
import '../../domain/repositories/group_repository.dart';
import 'auth_controller.dart';

/// Controller central para gestionar el flujo de peer review en el cliente.
/// Responsabilidades:
/// - Cargar assessments de una actividad
/// - Calcular peers pendientes para el usuario actual
/// - Crear nuevas evaluaciones (assessment) evitando duplicados
/// - Mantener agregados en memoria (resumen por actividad)
/// - Exponer helpers de elegibilidad y progreso
class PeerReviewController extends GetxController {
  final AssessmentRepository _assessmentRepository;
  final MembershipRepository _membershipRepository;
  final GroupRepository _groupRepository;

  PeerReviewController(
    this._assessmentRepository,
    this._membershipRepository,
    this._groupRepository,
  );

  AuthController get _auth => Get.find<AuthController>();

  String? get currentUserId => _auth.currentUser?.id;

  // Estado por actividad
  final RxMap<String, List<Assessment>> _assessmentsByActivity =
      <String, List<Assessment>>{}.obs; // activityId -> assessments
  final RxMap<String, ActivityPeerReviewSummary> _activitySummaries =
      <String, ActivityPeerReviewSummary>{}.obs; // activityId -> summary
  final RxMap<String, List<String>> _pendingPeersByActivity =
      <String, List<String>>{}
          .obs; // activityId -> list studentIds pending for current user
  final RxMap<String, Map<String, int>> _progress =
      <String, Map<String, int>>{}.obs; // activityId -> {'done':x,'total':y}
  final RxMap<String, CoursePeerReviewSummary> _courseSummaries =
      <String, CoursePeerReviewSummary>{}
          .obs; // courseId -> summary across activities

  // Métricas simples: duración evaluación (segundos) por assessment creado
  final RxMap<String, List<int>> _assessmentDurations =
      <String, List<int>>{}.obs; // activityId -> list durations
  final Map<String, DateTime> _enterEvaluateTimestamps =
      {}; // key activityId|peerId -> start time

  final isLoading = false.obs;
  final creating = false.obs;
  final errorMessage = ''.obs;

  /// Feature flag (puede setearse desde fuera si se necesita desactivar globalmente)
  final enablePeerReview = true.obs;

  /// Cargar datos de peer review para una actividad y el grupo del usuario
  Future<void> loadForActivity(CourseActivity activity,
      {String? groupId, List<String>? groupMemberIds}) async {
    if (!enablePeerReview.value) return;
    final userId = currentUserId;
    if (userId == null) return;
    // Solo tiene sentido si la actividad está en modo reviewing
    if (!activity.reviewing) return;
    try {
      isLoading.value = true;
      // 1. Cargar assessments existentes de la actividad
      final list =
          await _assessmentRepository.getAssessmentsByActivity(activity.id);
      _assessmentsByActivity[activity.id] = list;

      // 2. Obtener miembros del grupo (si no vienen) filtrando por groupId de la actividad para este usuario
      String? resolvedGroupId = groupId;
      List<String> members = groupMemberIds ?? [];
      if (resolvedGroupId == null || members.isEmpty) {
        // Determinar grupo del usuario dentro de la categoría de la actividad
        final myMemberships =
            await _membershipRepository.getMembershipsByUserId(userId);
        for (final m in myMemberships) {
          final g = await _groupRepository.getGroupById(m.groupId);
          if (g != null &&
              g.categoryId == activity.categoryId &&
              g.courseId == activity.courseId) {
            resolvedGroupId = g.id;
            break;
          }
        }
        if (resolvedGroupId != null) {
          final memberships = await _membershipRepository
              .getMembershipsByGroupId(resolvedGroupId);
          members = memberships.map((m) => m.userId).toList();
        }
      }

      // Si no se encontró grupo o es de tamaño <=1, no hay peer review para el usuario
      if (resolvedGroupId == null || members.length <= 1) {
        _pendingPeersByActivity[activity.id] = const [];
        _progress[activity.id] = {'done': 0, 'total': 0};
        await _refreshSummary(activity.id);
        return;
      }

      // 3. Calcular peers pendientes para el usuario
      final pending = await _assessmentRepository.listPendingPeerIds(
        activityId: activity.id,
        groupId: resolvedGroupId,
        reviewerId: userId,
        groupMemberIds: members,
      );
      _pendingPeersByActivity[activity.id] = pending;

      final existingMine = list.where((a) => a.reviewerId == userId).toList();
      // DEBUG OVERRIDE: permitir self-review -> meta = miembros del grupo (incluyéndome)
      // Lógica original: final totalNeeded = members.length - 1;
      final totalNeeded = members.length; // debug
      _progress[activity.id] = {
        'done': existingMine.length,
        'total': totalNeeded,
      };

      // 4. Resumen actividad (agregado) si visibilidad permite (profesor siempre, estudiantes según peerVisibility)
      await _refreshSummary(activity.id, force: true);
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
      update();
    }
  }

  /// Crear una nueva evaluación (assessment) asegurando no duplicar
  Future<Assessment?> createAssessment({
    required CourseActivity activity,
    required String groupId,
    required String studentId, // evaluado
    required int punctuality,
    required int contributions,
    required int commitment,
    required int attitude,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      errorMessage.value = 'Usuario no autenticado';
      return null;
    }
    if (!activity.reviewing) {
      errorMessage.value = 'La actividad no está en peer review';
      return null;
    }
    try {
      creating.value = true;
      final already = await _assessmentRepository.existsAssessment(
        activityId: activity.id,
        reviewerId: userId,
        studentId: studentId,
      );
      if (already) {
        errorMessage.value = 'Ya evaluaste a este compañero';
        return null;
      }
      final assessment = Assessment(
        id: '',
        activityId: activity.id,
        groupId: groupId,
        reviewerId: userId,
        studentId: studentId,
        punctualityScore: punctuality,
        contributionsScore: contributions,
        commitmentScore: commitment,
        attitudeScore: attitude,
        overallScorePersisted: null,
        createdAt: DateTime.now(),
        updatedAt: null,
      );
      final created = await _assessmentRepository.createAssessment(assessment);
      // Actualizar caches locales
      final list = _assessmentsByActivity[activity.id] ?? [];
      _assessmentsByActivity[activity.id] = [...list, created];
      // Recalcular pendientes y progreso
      final members = await _getGroupMemberIds(groupId);
      final pending = await _assessmentRepository.listPendingPeerIds(
        activityId: activity.id,
        groupId: groupId,
        reviewerId: userId,
        groupMemberIds: members,
      );
      _pendingPeersByActivity[activity.id] = pending;
      final existingMine = _assessmentsByActivity[activity.id]!
          .where((a) => a.reviewerId == userId)
          .length;
      _progress[activity.id] = {
        'done': existingMine,
        'total': members.length, // debug self-review
      };
      await _refreshSummary(activity.id, force: true);
      return created;
    } catch (e) {
      errorMessage.value = e.toString();
      return null;
    } finally {
      creating.value = false;
      update();
    }
  }

  /// Helper: IDs de miembros del grupo
  Future<List<String>> _getGroupMemberIds(String groupId) async {
    final memberships =
        await _membershipRepository.getMembershipsByGroupId(groupId);
    return memberships.map((m) => m.userId).toList(growable: false);
  }

  /// Resumen agregado de actividad
  Future<void> _refreshSummary(String activityId, {bool force = false}) async {
    if (!force && _activitySummaries.containsKey(activityId)) return;
    try {
      final summary =
          await _assessmentRepository.computeActivitySummary(activityId);
      _activitySummaries[activityId] = summary;
    } catch (e) {
      // no romper flujo, solo log interno
    }
  }

  // ==== Getters públicos ====
  List<Assessment> assessmentsForActivity(String activityId) =>
      _assessmentsByActivity[activityId] ?? const [];

  ActivityPeerReviewSummary? activitySummary(String activityId) =>
      _activitySummaries[activityId];

  CoursePeerReviewSummary? courseSummary(String courseId) =>
      _courseSummaries[courseId];

  List<String> pendingPeers(String activityId) =>
      _pendingPeersByActivity[activityId] ?? const [];

  Map<String, int> progressFor(String activityId) =>
      _progress[activityId] ?? const {'done': 0, 'total': 0};

  bool isCompleted(String activityId) {
    final p = progressFor(activityId);
    return p['total'] != null && p['total']! > 0 && p['done'] == p['total'];
  }

  /// Elegibilidad para que un estudiante vea y haga peer review:
  bool canStudentReview(CourseActivity activity,
      {required bool isMemberOfGroup}) {
    if (!enablePeerReview.value) return false;
    if (!activity.reviewing) return false;
    if (!isMemberOfGroup) return false;
    // Debe haber pasado dueDate (por regla de activación ya pasó, pero defensivo)
    if (activity.dueDate != null &&
        DateTime.now().isBefore(activity.dueDate!)) {
      return false;
    }
    return true;
  }

  /// Estudiante puede ver resultados agregados (public) cuando completó todas sus evaluaciones
  bool canStudentSeePublicResults(CourseActivity activity) {
    if (activity.peerVisibility != 'public') return false;
    return isCompleted(activity.id);
  }

  /// Profesor (dueño curso) siempre puede ver summary
  bool canTeacherSeeSummary(CourseActivity activity, String teacherId) {
    return activity.createdBy == teacherId ||
        true; // fallback if createdBy no es teacher, se podría validar con CourseController
  }

  /// Invalidate caches (usar cuando cambie visibilidad o se añada assessment externo)
  void invalidateActivity(String activityId) {
    _activitySummaries.remove(activityId);
    _pendingPeersByActivity.remove(activityId);
    _progress.remove(activityId);
  }

  /// Cargar y cachear resumen global del curso a partir de actividades (ids provistas)
  Future<CoursePeerReviewSummary?> loadCourseSummary(
      {required String courseId,
      required List<String> activityIds,
      bool force = false}) async {
    if (!force && _courseSummaries.containsKey(courseId))
      return _courseSummaries[courseId];
    if (activityIds.isEmpty) return null;
    try {
      isLoading.value = true;
      final summary =
          await _assessmentRepository.computeCourseSummary(activityIds);
      _courseSummaries[courseId] = summary;
      return summary;
    } catch (e) {
      errorMessage.value = e.toString();
      return null;
    } finally {
      isLoading.value = false;
      update();
    }
  }

  // === Métricas ===
  void markEnterEvaluate(String activityId, String peerId) {
    _enterEvaluateTimestamps['$activityId|$peerId'] = DateTime.now();
  }

  void markFinishEvaluate(String activityId, String peerId) {
    final key = '$activityId|$peerId';
    final start = _enterEvaluateTimestamps.remove(key);
    if (start != null) {
      final dur = DateTime.now().difference(start).inSeconds;
      final list = _assessmentDurations[activityId] ?? [];
      _assessmentDurations[activityId] = [...list, dur];
    }
  }

  double averageEvaluationDuration(String activityId) {
    final list = _assessmentDurations[activityId];
    if (list == null || list.isEmpty) return 0;
    return list.reduce((a, b) => a + b) / list.length;
  }
}
