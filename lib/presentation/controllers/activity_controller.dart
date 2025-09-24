import 'package:get/get.dart';
import '../../domain/models/course_activity.dart';
import '../../domain/use_cases/activity/get_course_activities_for_student_use_case.dart';
import 'auth_controller.dart';
import '../../domain/repositories/group_repository.dart';
import '../../domain/repositories/membership_repository.dart';
import '../../domain/repositories/course_activity_repository.dart';
import 'course_controller.dart';

class ActivityController extends GetxController {
  final GetCourseActivitiesForStudentUseCase _getActivities;
  final GroupRepository _groupRepository;
  final MembershipRepository _membershipRepository;
  final CourseActivityRepository _activityRepository;
  // We also need repo to create activities; use DI to inject via use case existing repos
  // but for simplicity, we'll reuse the CourseActivityRepository through a lite facade

  ActivityController(
    this._getActivities,
    this._groupRepository,
    this._membershipRepository,
    this._activityRepository,
  );

  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final activitiesByCourse = <String, List<CourseActivity>>{}.obs;

  AuthController get _auth => Get.find<AuthController>();
  String? get currentUserId => _auth.currentUser?.id;

  Future<void> loadForCourse(String courseId) async {
    final userId = currentUserId;
    if (userId == null || userId.isEmpty) return;
    try {
      isLoading.value = true;
      // Si el usuario es profesor del curso, cargamos todas las actividades del curso
      final course = await Get.find<CourseController>().getCourseById(courseId);
      List<CourseActivity> list;
      if (course != null && course.teacherId == userId) {
        list = await _activityRepository.getActivitiesByCourse(courseId);
        // DEBUG LOG
        // ignore: avoid_print
        print(
            '[ACTIVITY_CONTROLLER] Profesor: cargadas ${list.length} actividades para curso $courseId');
      } else {
        list = await _getActivities(GetCourseActivitiesForStudentParams(
            courseId: courseId, userId: userId));
        // ignore: avoid_print
        print(
            '[ACTIVITY_CONTROLLER] Estudiante: cargadas ${list.length} actividades visibles para curso $courseId');
      }
      for (final a in list) {
        // ignore: avoid_print
        print(
            '[ACTIVITY_CONTROLLER] Activity -> id=${a.id} title="${a.title}" active=${a.isActive} reviewing=${a.reviewing} due=${a.dueDate}');
      }
      activitiesByCourse[courseId] = list;
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
      update();
    }
  }

  List<CourseActivity> previewForCourse(String courseId, [int take = 3]) {
    final list = activitiesByCourse[courseId] ?? const [];
    // No aplicar filtros adicionales; solo ordenar por createdAt desc para que la más reciente aparezca primero
    final sorted = [...list]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(take).toList();
  }

  /// Encuentra (de forma perezosa) el nombre del grupo del usuario a través del cual recibe la actividad.
  /// Busca una membresía del usuario en la categoría de la actividad y devuelve el nombre del grupo.
  Future<String?> resolveMyGroupNameForActivity(CourseActivity a) async {
    final userId = currentUserId;
    if (userId == null) return null;
    final my = await _membershipRepository.getMembershipsByUserId(userId);
    for (final m in my) {
      final g = await _groupRepository.getGroupById(m.groupId);
      if (g != null &&
          g.categoryId == a.categoryId &&
          g.courseId == a.courseId) {
        return g.name;
      }
    }
    return null;
  }

  Future<CourseActivity?> createActivity(CourseActivity activity) async {
    try {
      isLoading.value = true;
      final created = await _activityRepository.createActivity(activity);
      // refresh cache
      await loadForCourse(created.courseId);
      return created;
    } catch (e) {
      errorMessage.value = e.toString();
      return null;
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<CourseActivity?> updateActivity(CourseActivity activity) async {
    try {
      isLoading.value = true;
      final updated = await _activityRepository.updateActivity(activity);
      await loadForCourse(updated.courseId);
      return updated;
    } catch (e) {
      errorMessage.value = e.toString();
      return null;
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<bool> deleteActivity(String activityId, String courseId) async {
    try {
      isLoading.value = true;
      final ok = await _activityRepository.deleteActivity(activityId);
      await loadForCourse(courseId);
      return ok;
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    } finally {
      isLoading.value = false;
      update();
    }
  }

  /// Activa el peer review para una actividad (solo profesor y después del dueDate)
  /// peerVisibility: 'public' o 'private'
  Future<CourseActivity?> requestPeerReview({
    required String activityId,
    String peerVisibility = 'private',
  }) async {
    try {
      isLoading.value = true;
      // localizar actividad actual
      CourseActivity? activity;
      activitiesByCourse.forEach((_, list) {
        for (final a in list) {
          if (a.id == activityId) activity = a;
        }
      });
      activity ??= await _activityRepository.getActivityById(activityId);
      if (activity == null) throw Exception('Actividad no encontrada');

      // Validar rol profesor del curso
      final course =
          await Get.find<CourseController>().getCourseById(activity!.courseId);
      final userId = currentUserId;
      if (course == null || userId == null || course.teacherId != userId) {
        throw Exception('No autorizado para activar peer review');
      }
      // DEBUG OVERRIDE: permitir activación antes de due date para pruebas.
      // Lógica original comentada temporalmente:
      // if (activity!.dueDate == null || DateTime.now().isBefore(activity!.dueDate!)) {
      //   throw Exception('La actividad aún no ha pasado su due date');
      // }
      // Ya activo?
      if (activity!.reviewing) {
        // Permitir cambiar visibilidad private->public
        if (activity!.peerVisibility == 'private' &&
            peerVisibility == 'public') {
          final updated = activity!.copyWith(peerVisibility: 'public');
          return await updateActivity(updated);
        }
        return activity; // nada que hacer
      }
      final updated =
          activity!.copyWith(reviewing: true, peerVisibility: peerVisibility);
      return await updateActivity(updated);
    } catch (e) {
      errorMessage.value = e.toString();
      return null;
    } finally {
      isLoading.value = false;
      update();
    }
  }
}
