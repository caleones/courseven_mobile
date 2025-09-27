import '../models/enrollment.dart';


abstract class EnrollmentRepository {
  
  Future<Enrollment?> getEnrollmentById(String enrollmentId);

  
  Future<List<Enrollment>> getEnrollmentsByStudent(String studentId);

  
  Future<List<Enrollment>> getEnrollmentsByCourse(String courseId);

  
  Future<Enrollment> createEnrollment(Enrollment enrollment);

  
  Future<Enrollment> updateEnrollment(Enrollment enrollment);

  
  Future<bool> deleteEnrollment(String enrollmentId);

  
  Future<bool> isStudentEnrolledInCourse(String studentId, String courseId);

  
  Future<List<Enrollment>> getActiveEnrollments();

  
  Future<List<Enrollment>> getEnrollmentsPaginated({
    int page = 1,
    int limit = 10,
    String? studentId,
    String? courseId,
  });

  
  Future<int> getEnrollmentCountByCourse(String courseId);

  
  Future<int> getEnrollmentCountByStudent(String studentId);
}
