import 'package:get/get.dart';
import '../../domain/models/enrollment.dart';
import '../../domain/use_cases/enrollment/enroll_to_course_use_case.dart';
import '../../domain/use_cases/enrollment/get_my_enrollments_use_case.dart';
import '../../domain/models/course.dart';
import '../../domain/models/user.dart';
import '../../domain/repositories/course_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/repositories/enrollment_repository.dart';
import '../controllers/auth_controller.dart';

class EnrollmentController extends GetxController {
  final EnrollToCourseUseCase _enrollToCourse;
  final GetMyEnrollmentsUseCase _getMyEnrollments;
  final CourseRepository _courseRepository;
  final UserRepository _userRepository;
  EnrollmentController(this._enrollToCourse, this._getMyEnrollments,
      this._courseRepository, this._userRepository);

  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final myEnrollments = <Enrollment>[].obs;
  // Enrichment caches
  final Map<String, Course> _courses = {};
  final Map<String, User> _users = {};

  // Teacher-side / course-centric data (counts + listings)
  final enrollmentCounts = <String, int>{}.obs; // courseId -> count
  final enrollmentsByCourse =
      <String, List<Enrollment>>{}.obs; // courseId -> list
  final _loadingCourseIds =
      <String>{}.obs; // courseIds currently loading full list
  final _loadingCountCourseIds =
      <String>{}.obs; // courseIds currently loading count only

  AuthController get _auth => Get.find<AuthController>();
  String? get currentUserId => _auth.currentUser?.id;

  Future<void> loadMyEnrollments() async {
    final userId = currentUserId;
    if (userId == null || userId.isEmpty) return;
    try {
      isLoading.value = true;
      final list = await _getMyEnrollments(userId);
      myEnrollments.assignAll(list);
      // Enrich: prefetch course and teacher for display
      for (final e in list) {
        if (!_courses.containsKey(e.courseId)) {
          final c = await _courseRepository.getCourseById(e.courseId);
          if (c != null) _courses[e.courseId] = c;
        }
        final course = _courses[e.courseId];
        if (course != null && !_users.containsKey(course.teacherId)) {
          final u = await _userRepository.getUserById(course.teacherId);
          if (u != null) _users[course.teacherId] = u;
        }
      }
      update();
    } catch (e) {
      final errorMsg = e.toString();
      // Handle specific 401 error case
      if (errorMsg.contains('401') ||
          errorMsg.toLowerCase().contains('unauthorized')) {
        await _handleAuthError();
      } else {
        errorMessage.value = 'Error al cargar inscripciones: ${errorMsg}';
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<Enrollment?> joinByCode(String joinCode) async {
    final userId = currentUserId;
    if (userId == null || userId.isEmpty) {
      errorMessage.value = 'Usuario no autenticado';
      return null;
    }
    try {
      isLoading.value = true;
      final created = await _enrollToCourse(
        EnrollToCourseParams(userId: userId, joinCode: joinCode.trim()),
      );
      // refresh list
      await loadMyEnrollments();
      return created;
    } catch (e) {
      errorMessage.value = e.toString();
      return null;
    } finally {
      isLoading.value = false;
      update();
    }
  }

  // Accessors for UI binding
  String getCourseTitle(String courseId) => _courses[courseId]?.name ?? 'Curso';
  String getCourseTeacherName(String courseId) {
    final tId = _courses[courseId]?.teacherId;
    if (tId == null) return '';
    final u = _users[tId];
    return u != null ? '${u.firstName} ${u.lastName}' : '';
  }

  /// Permite actualizar el título de un curso en caché (ej. después de habilitar o renombrar).
  void overrideCourseTitle(String courseId, String newTitle) {
    final existing = _courses[courseId];
    if (existing != null) {
      _courses[courseId] = existing.copyWith(name: newTitle);
      update();
    }
  }

  // ================= Course-centric (teacher or viewer) helpers =================

  bool isLoadingCourse(String courseId) => _loadingCourseIds.contains(courseId);
  bool isLoadingCount(String courseId) =>
      _loadingCountCourseIds.contains(courseId);

  int enrollmentCountFor(String courseId) => enrollmentCounts[courseId] ?? 0;
  List<Enrollment> enrollmentsFor(String courseId) =>
      enrollmentsByCourse[courseId] ?? const [];

  Future<void> loadEnrollmentCountForCourse(String courseId,
      {bool force = false}) async {
    if (courseId.isEmpty) return;
    if (!force && enrollmentCounts.containsKey(courseId)) return;
    if (_loadingCountCourseIds.contains(courseId)) return;
    _loadingCountCourseIds.add(courseId);
    update();
    try {
      final repo = Get.find<EnrollmentRepository>();
      final c = await repo.getEnrollmentCountByCourse(courseId);
      enrollmentCounts[courseId] = c;
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      _loadingCountCourseIds.remove(courseId);
      update();
    }
  }

  Future<void> loadEnrollmentsForCourse(String courseId,
      {bool force = false}) async {
    if (courseId.isEmpty) return;
    if (!force && enrollmentsByCourse.containsKey(courseId)) return;
    if (_loadingCourseIds.contains(courseId)) return;
    _loadingCourseIds.add(courseId);
    update();
    try {
      final repo = Get.find<EnrollmentRepository>();
      final list = await repo.getEnrollmentsByCourse(courseId);
      enrollmentsByCourse[courseId] = list;
      enrollmentCounts[courseId] = list.length; // keep count in sync
      // Prefetch user metadata for each enrollment (students)
      for (final e in list) {
        if (!_users.containsKey(e.studentId)) {
          final u = await _userRepository.getUserById(e.studentId);
          if (u != null) _users[e.studentId] = u;
        }
      }
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      _loadingCourseIds.remove(courseId);
      update();
    }
  }

  String userName(String userId) {
    final u = _users[userId];
    if (u == null) return 'Estudiante';
    final parts =
        [u.firstName, u.lastName].where((p) => p.trim().isNotEmpty).toList();
    return parts.isEmpty ? 'Estudiante' : parts.join(' ');
  }

  Future<void> _handleAuthError() async {
    // Intentar renovar el token automáticamente
    final authController = Get.find<AuthController>();
    final success = await authController.handle401Error();

    if (success) {
      // Token renovado, reintentar cargar datos
      errorMessage.value = 'Sesión renovada, reintentando...';
      await loadMyEnrollments(); // Reintentar la operación
    } else {
      // No se pudo renovar, limpiar datos
      myEnrollments.clear();
      errorMessage.value =
          'Sesión expirada. Por favor, inicia sesión nuevamente.';
    }
  }
}
