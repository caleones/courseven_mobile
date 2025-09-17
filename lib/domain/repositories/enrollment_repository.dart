import '../models/enrollment.dart';

/// Repositorio abstracto para manejo de inscripciones
abstract class EnrollmentRepository {
  /// Obtener inscripción por ID
  Future<Enrollment?> getEnrollmentById(String enrollmentId);

  /// Obtener inscripciones por estudiante
  Future<List<Enrollment>> getEnrollmentsByStudent(String studentId);

  /// Obtener inscripciones por curso
  Future<List<Enrollment>> getEnrollmentsByCourse(String courseId);

  /// Crear nueva inscripción
  Future<Enrollment> createEnrollment(Enrollment enrollment);

  /// Actualizar inscripción existente
  Future<Enrollment> updateEnrollment(Enrollment enrollment);

  /// Eliminar inscripción (soft delete)
  Future<bool> deleteEnrollment(String enrollmentId);

  /// Verificar si estudiante está inscrito en curso
  Future<bool> isStudentEnrolledInCourse(String studentId, String courseId);

  /// Obtener inscripciones activas
  Future<List<Enrollment>> getActiveEnrollments();

  /// Obtener inscripciones paginadas
  Future<List<Enrollment>> getEnrollmentsPaginated({
    int page = 1,
    int limit = 10,
    String? studentId,
    String? courseId,
  });

  /// Obtener número de estudiantes inscritos en curso
  Future<int> getEnrollmentCountByCourse(String courseId);

  /// Obtener número de cursos del estudiante
  Future<int> getEnrollmentCountByStudent(String studentId);
}
