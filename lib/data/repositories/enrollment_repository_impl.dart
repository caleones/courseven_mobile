import '../../domain/models/enrollment.dart';
import '../models/enrollment_model.dart';
import '../../domain/repositories/enrollment_repository.dart';
import '../services/roble_service.dart';

class EnrollmentRepositoryImpl implements EnrollmentRepository {
  final RobleService _service;
  final Future<String?> Function()? _getAccessToken;

  EnrollmentRepositoryImpl(this._service,
      {Future<String?> Function()? getAccessToken})
      : _getAccessToken = getAccessToken;

  Future<String> _requireToken() async {
    if (_getAccessToken != null) {
      final t = await _getAccessToken!();
      if (t != null && t.isNotEmpty) return t;
    }
    throw Exception('Access token no disponible');
  }

  Enrollment _fromMap(Map<String, dynamic> m) =>
      EnrollmentModel.fromJson(m).toEntity();

  Map<String, dynamic> _toRecord(Enrollment e) => EnrollmentModel(
        id: e.id,
        studentId: e.studentId,
        courseId: e.courseId,
        enrolledAt: e.enrolledAt,
        isActive: e.isActive,
      ).toJson();

  @override
  Future<Enrollment> createEnrollment(Enrollment enrollment) async {
    final token = await _requireToken();
    final record = _toRecord(enrollment);
    if (record['_id'] == null || (record['_id'] as String).isEmpty) {
      record.remove('_id');
    }
    
    record['status'] = record['status'] ?? 'active';
    final res =
        await _service.insertEnrollment(accessToken: token, record: record);
    final inserted = (res['inserted'] as List?) ?? const [];
    if (inserted.isEmpty) {
      throw Exception('Insert de enrollment no retornó registros');
    }
    return _fromMap(inserted.first as Map<String, dynamic>);
  }

  @override
  Future<Enrollment?> getEnrollmentById(String enrollmentId) async {
    final token = await _requireToken();
    final rows = await _service
        .readEnrollments(accessToken: token, query: {'_id': enrollmentId});
    if (rows.isEmpty) return null;
    return _fromMap(rows.first);
  }

  @override
  Future<List<Enrollment>> getEnrollmentsByStudent(String studentId) async {
    final token = await _requireToken();
    final rows = await _service
        .readEnrollments(accessToken: token, query: {'user_id': studentId});
    return rows.map(_fromMap).toList(growable: false);
  }

  @override
  Future<List<Enrollment>> getEnrollmentsByCourse(String courseId) async {
    final token = await _requireToken();
    final rows = await _service.readEnrollments(accessToken: token, query: {
      'course_id': courseId,
      'is_active': 'true',
    });
    return rows.map(_fromMap).toList(growable: false);
  }

  @override
  Future<bool> isStudentEnrolledInCourse(
      String studentId, String courseId) async {
    final token = await _requireToken();
    final rows = await _service.readEnrollments(accessToken: token, query: {
      'user_id': studentId,
      'course_id': courseId,
      'is_active': 'true',
    });
    return rows.isNotEmpty;
  }

  
  @override
  Future<bool> deleteEnrollment(String enrollmentId) async {
    throw UnimplementedError();
  }

  @override
  Future<List<Enrollment>> getActiveEnrollments() async {
    return [];
  }

  @override
  Future<List<Enrollment>> getEnrollmentsPaginated(
      {int page = 1,
      int limit = 10,
      String? studentId,
      String? courseId}) async {
    return [];
  }

  @override
  Future<Enrollment> updateEnrollment(Enrollment enrollment) async {
    final token = await _requireToken();
    if (enrollment.id.isEmpty) {
      throw Exception('updateEnrollment requiere _id');
    }
    final updates = {
      'user_id': enrollment.studentId,
      'course_id': enrollment.courseId,
      'enrolled_at': enrollment.enrolledAt.toIso8601String(),
      'is_active': enrollment.isActive,
    };
    final res = await _service.updateRow(
      accessToken: token,
      table: 'enrollments',
      id: enrollment.id,
      updates: updates,
    );
    
    Map<String, dynamic>? updated;
    if (res['updated'] is List && (res['updated'] as List).isNotEmpty) {
      updated = (res['updated'] as List).first as Map<String, dynamic>;
    } else if (res['data'] is Map<String, dynamic>) {
      updated = res['data'] as Map<String, dynamic>;
    } else {
      
      updated = res.cast<String, dynamic>();
    }
    return _fromMap(updated);
  }

  @override
  Future<int> getEnrollmentCountByCourse(String courseId) async {
    final token = await _requireToken();
    final rows = await _service.readEnrollments(accessToken: token, query: {
      'course_id': courseId,
      'is_active': 'true',
    });
    return rows.length;
  }

  @override
  Future<int> getEnrollmentCountByStudent(String studentId) async {
    final token = await _requireToken();
    final rows = await _service
        .readEnrollments(accessToken: token, query: {'user_id': studentId});
    return rows.length;
  }
}
