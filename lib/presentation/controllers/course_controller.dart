import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/models/course.dart';
import '../../domain/use_cases/course/create_course_use_case.dart';
import '../../domain/repositories/course_repository.dart';
import 'auth_controller.dart';
import 'enrollment_controller.dart';

class CourseController extends GetxController {
  final CreateCourseUseCase _createCourseUseCase;
  final CourseRepository _courseRepository;

  CourseController(this._createCourseUseCase, this._courseRepository);

  // Estado
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final createdCourse = Rxn<Course>();
  final teacherCourses = <Course>[].obs;
  // Cache reactivo por id para lecturas inmediatas
  final coursesCache = <String, Course>{}.obs;

  AuthController get _auth => Get.find<AuthController>();

  String? get currentTeacherId => _auth.currentUser?.id;

  @override
  void onInit() {
    super.onInit();
    // Si hay sesión, cargo cursos del profesor
    if (currentTeacherId != null && currentTeacherId!.isNotEmpty) {
      loadMyTeachingCourses();
    }
  }

  Future<void> loadMyTeachingCourses() async {
    final teacherId = currentTeacherId;
    if (teacherId == null || teacherId.isEmpty) return;
    try {
      isLoading.value = true;
      final list = await _courseRepository.getCoursesByTeacher(teacherId);
      teacherCourses.assignAll(list);
      for (final c in list) {
        coursesCache[c.id] = c;
      }
    } catch (e) {
      debugPrint('[COURSE_CONTROLLER] loadMyTeachingCourses error: $e');
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<bool> canCreateMoreCourses() async {
    try {
      final teacherId = currentTeacherId;
      if (teacherId == null || teacherId.isEmpty) return false;
      final existing = await _courseRepository.getCoursesByTeacher(teacherId);
      return existing.length < CreateCourseUseCase.maxCoursesPerTeacher;
    } catch (_) {
      return false;
    }
  }

  /// Obtiene un curso por id. Intenta primero del caché local
  /// (teacherCourses) y si no está, consulta al repositorio.
  Future<Course?> getCourseById(String courseId) async {
    try {
      final cached = coursesCache[courseId];
      if (cached != null) return cached;
      final local = teacherCourses.firstWhereOrNull((c) => c.id == courseId);
      if (local != null) {
        coursesCache[courseId] = local;
        return local;
      }
      final fetched = await _courseRepository.getCourseById(courseId);
      if (fetched != null) coursesCache[courseId] = fetched;
      return fetched;
    } catch (_) {
      return null;
    }
  }

  Future<Course?> createCourse({
    required String name,
    required String description,
  }) async {
    if (isLoading.value) return null;
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final teacherId = currentTeacherId;
      if (teacherId == null || teacherId.isEmpty) {
        throw Exception('Usuario no autenticado');
      }

      final params = CreateCourseParams(
        name: name,
        description: description,
        teacherId: teacherId,
      );

      final course = await _createCourseUseCase(params);
      createdCourse.value = course;
      coursesCache[course.id] = course;
      // refrescar lista del profesor
      await loadMyTeachingCourses();
      Get.snackbar(
        'Curso creado',
        '"${course.name}" se creó correctamente',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFFFFD700),
        colorText: const Color(0xFF0D0D0D),
      );
      return course;
    } catch (e) {
      errorMessage.value = e.toString();
      Get.snackbar(
        'No se pudo crear',
        errorMessage.value,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red[400],
        colorText: Colors.white,
      );
      return null;
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<Course?> updateCourse(Course course) async {
    try {
      // Enforce that only the real course teacher can update
      final myId = currentTeacherId;
      if (myId == null || myId.isEmpty || myId != course.teacherId) {
        errorMessage.value = 'No tienes permisos para editar este curso';
        Get.snackbar(
          'Acceso denegado',
          'Solo el profesor del curso puede editarlo',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red[400],
          colorText: Colors.white,
        );
        return null;
      }
      isLoading.value = true;
      final updated =
          await _courseRepository.updateCourse(course, partial: true);
      notifyCourseChanged(updated);
      return updated;
    } catch (e) {
      errorMessage.value = e.toString();
      return null;
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<bool> deleteCourse(String courseId) async {
    try {
      // Enforce that only the real course teacher can delete (soft)
      final course = await getCourseById(courseId);
      final myId = currentTeacherId;
      if (course == null ||
          myId == null ||
          myId.isEmpty ||
          myId != course.teacherId) {
        errorMessage.value = 'No tienes permisos para eliminar este curso';
        Get.snackbar(
          'Acceso denegado',
          'Solo el profesor del curso puede eliminarlo',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red[400],
          colorText: Colors.white,
        );
        return false;
      }
      isLoading.value = true;
      final ok = await _courseRepository.deleteCourse(courseId);
      if (ok) {
        coursesCache.remove(courseId);
        teacherCourses.removeWhere((c) => c.id == courseId);
      }
      return ok;
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<Course?> setCourseActive(String courseId, bool active) async {
    try {
      final myId = currentTeacherId;
      final course = await getCourseById(courseId);
      if (course == null || myId == null || myId != course.teacherId) {
        Get.snackbar(
          'Acceso denegado',
          'No puedes modificar este curso',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red[400],
          colorText: Colors.white,
        );
        return null;
      }
      if (active) {
        final activeCount = teacherCourses.where((c) => c.isActive).length;
        if (activeCount >= CreateCourseUseCase.maxCoursesPerTeacher) {
          Get.snackbar(
            'Límite alcanzado',
            'Ya tienes $activeCount cursos activos (máx ${CreateCourseUseCase.maxCoursesPerTeacher}). Deshabilita otro para continuar.',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red[400],
            colorText: Colors.white,
          );
          return null;
        }
      }
      isLoading.value = true;
      final updated = await _courseRepository.setCourseActive(courseId, active);
      notifyCourseChanged(updated);
      // Aseguramos refresco completo para que listas y conteos reaccionen
      await loadMyTeachingCourses();
      Get.snackbar(
        active ? 'Curso habilitado' : 'Curso deshabilitado',
        active
            ? 'Ahora puedes crear actividades, categorías y grupos.'
            : 'Se ha deshabilitado. No podrás crear elementos hasta habilitarlo.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: active ? Colors.green[400] : Colors.orange[400],
        colorText: Colors.white,
      );
      return updated;
    } catch (e) {
      errorMessage.value = e.toString();
      Get.snackbar(
        'Error',
        errorMessage.value,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red[400],
        colorText: Colors.white,
      );
      return null;
    } finally {
      isLoading.value = false;
      update();
    }
  }

  /// Helper para centralizar la verificación de si un curso está activo
  /// antes de crear entidades (actividades, categorías, grupos, etc.).
  /// Retorna true si el curso está activo o no se pudo determinar (prefiere permitir en duda),
  /// y muestra un snackbar y retorna false si está inactivo.
  Future<bool> ensureCourseActiveOrWarn(
      String courseId, String entityLabel) async {
    try {
      final course = await getCourseById(courseId);
      if (course != null && !course.isActive) {
        Get.snackbar(
          'Curso inactivo',
          'Habilita el curso antes de crear $entityLabel',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange[400],
          colorText: Colors.white,
        );
        return false;
      }
      return true; // si no se encontró el curso, no bloquear estrictamente
    } catch (_) {
      return true; // en caso de error silencioso no bloquear
    }
  }

  /// Actualiza caches y lista reactiva tras un cambio de curso.
  void notifyCourseChanged(Course updated) {
    coursesCache[updated.id] = updated;
    final idx = teacherCourses.indexWhere((c) => c.id == updated.id);
    if (idx != -1) {
      teacherCourses[idx] = updated;
      teacherCourses.refresh();
    }
    // También actualizar EnrollmentController si está presente
    if (Get.isRegistered<EnrollmentController>()) {
      final enrollCtrl = Get.find<EnrollmentController>();
      enrollCtrl.overrideCourseTitle(updated.id, updated.name);
    }
  }
}
