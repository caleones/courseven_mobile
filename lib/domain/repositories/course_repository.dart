import '../models/course.dart';

/// Repositorio abstracto para manejo de cursos
abstract class CourseRepository {
  /// Obtener curso por ID
  Future<Course?> getCourseById(String courseId);

  /// Obtener cursos por categoría
  Future<List<Course>> getCoursesByCategory(String categoryId);

  /// Obtener cursos por profesor
  Future<List<Course>> getCoursesByTeacher(String teacherId);

  /// Crear nuevo curso
  Future<Course> createCourse(Course course);

  /// Actualizar curso existente
  Future<Course> updateCourse(Course course);

  /// Eliminar curso (soft delete)
  Future<bool> deleteCourse(String courseId);

  /// Buscar cursos por título
  Future<List<Course>> searchCoursesByTitle(String title);

  /// Obtener cursos activos
  Future<List<Course>> getActiveCourses();

  /// Obtener cursos paginados
  Future<List<Course>> getCoursesPaginated({
    int page = 1,
    int limit = 10,
    String? categoryId,
    String? teacherId,
  });

  /// Obtener cursos ordenados
  Future<List<Course>> getCoursesOrdered();

  /// Actualizar orden de cursos
  Future<bool> updateCoursesOrder(List<String> courseIds);
}
