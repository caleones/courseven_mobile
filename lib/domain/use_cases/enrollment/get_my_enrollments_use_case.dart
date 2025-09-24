import '../../models/enrollment.dart';
import '../../repositories/enrollment_repository.dart';

class GetMyEnrollmentsUseCase {
  final EnrollmentRepository _enrollmentRepository;
  GetMyEnrollmentsUseCase(this._enrollmentRepository);

  Future<List<Enrollment>> call(String userId) async {
    return _enrollmentRepository.getEnrollmentsByStudent(userId);
  }
}
