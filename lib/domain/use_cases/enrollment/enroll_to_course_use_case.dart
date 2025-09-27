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

  
  
  
  
  
  
  Future<Enrollment> call(EnrollToCourseParams p) async {
    
    final course = await _courseRepository.getCourseByJoinCode(p.joinCode);
    if (course == null) {
      throw Exception('Código de ingreso inválido');
    }

    
    if (course.teacherId == p.userId) {
      throw Exception(
          'No puedes inscribirte como estudiante en tu propio curso');
    }

    
    final myEnrollments =
        await _enrollmentRepository.getEnrollmentsByStudent(p.userId);
    Enrollment? existing;
    for (final e in myEnrollments) {
      if (e.courseId == course.id) {
        existing = e;
        break;
      }
    }

    
    if (existing != null && existing.isActive) {
      throw Exception('Ya estás inscrito en este curso');
    }

    
    if (existing != null && !existing.isActive) {
      final reactivated = await _enrollmentRepository.updateEnrollment(
        existing.copyWith(isActive: true, enrolledAt: DateTime.now()),
      );
      return reactivated;
    }

    
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
