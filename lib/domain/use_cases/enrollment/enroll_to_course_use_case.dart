import '../../models/enrollment.dart';
import '../../repositories/enrollment_repository.dart';
import '../../repositories/course_repository.dart';

class EnrollToCourseParams {
  final String userId;
  final String joinCode;
  const EnrollToCourseParams({required this.userId, required this.joinCode});
}

class EnrollToCourseUseCase {
  final EnrollmentRepository _enrollmentRepository;
  final CourseRepository _courseRepository;
  EnrollToCourseUseCase(this._enrollmentRepository, this._courseRepository);

  /// Busca el curso por joinCode y crea la inscripción del usuario si no existe.
  /// Lanza excepción si el código no es válido o ya está inscrito.
  Future<Enrollment> call(EnrollToCourseParams p) async {
    // 1) Buscar curso por joinCode
    final course = await _courseRepository.getCourseByJoinCode(p.joinCode);
    if (course == null) {
      throw Exception('Código de ingreso inválido');
    }

    // 2) Verificar si ya está inscrito
    final already = await _enrollmentRepository.isStudentEnrolledInCourse(
        p.userId, course.id);
    if (already) {
      throw Exception('Ya estás inscrito en este curso');
    }

    // 3) Crear inscripción
    final now = DateTime.now();
    final enrollment = Enrollment(
      id: '',
      studentId: p.userId,
      courseId: course.id,
      enrolledAt: now,
      isActive: true,
    );
    final created = await _enrollmentRepository.createEnrollment(enrollment);
    return created;
  }
}
