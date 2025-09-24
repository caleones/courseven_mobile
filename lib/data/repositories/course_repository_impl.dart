import 'package:flutter/foundation.dart';
import '../../domain/models/course.dart';
import '../models/course_model.dart';
import '../../domain/repositories/course_repository.dart';
import '../services/roble_service.dart';

class CourseRepositoryImpl implements CourseRepository {
  final RobleService _service;
  final Future<String?> Function()? _getAccessToken;

  CourseRepositoryImpl(this._service,
      {Future<String?> Function()? getAccessToken})
      : _getAccessToken = getAccessToken;

  Future<String> _requireToken() async {
    if (_getAccessToken != null) {
      final t = await _getAccessToken!();
      if (t != null && t.isNotEmpty) return t;
    }
    throw Exception('Access token no disponible');
  }

  Course _fromMap(Map<String, dynamic> map) =>
      CourseModel.fromJson(map).toEntity();

  Map<String, dynamic> _toRecord(Course c) => CourseModel(
        id: c.id,
        name: c.name,
        description: c.description,
        joinCode: c.joinCode,
        teacherId: c.teacherId,
        createdAt: c.createdAt,
        isActive: c.isActive,
      ).toJson();

  @override
  Future<Course?> getCourseById(String courseId) async {
    try {
      final token = await _requireToken();
      // Permitimos leer cursos aunque estén inactivos para que aparezcan en listados docente.
      final rows = await _service.readCourses(
        accessToken: token,
        query: {'_id': courseId},
      );
      if (rows.isEmpty) return null;
      return _fromMap(rows.first);
    } catch (e) {
      debugPrint('[COURSE_REPO] getCourseById error: $e');
      return null;
    }
  }

  @override
  Future<List<Course>> getCoursesByCategory(String categoryId) async {
    // Category is not a Course attribute in this model; return empty list / or throw
    debugPrint('[COURSE_REPO] getCoursesByCategory not supported');
    return [];
  }

  @override
  Future<List<Course>> getCoursesByTeacher(String teacherId) async {
    final token = await _requireToken();
    final rows = await _service.readCoursesByTeacher(
      accessToken: token,
      teacherId: teacherId,
    );
    // NO filtramos por is_active: el docente necesita ver también inactivos.
    return rows.map(_fromMap).toList(growable: false);
  }

  @override
  Future<Course> createCourse(Course course) async {
    final token = await _requireToken();
    final record = _toRecord(course);
    // remove id if client-generated empty
    if (record['_id'] == null || (record['_id'] as String).isEmpty) {
      record.remove('_id');
    }
    final res = await _service.insertCourse(accessToken: token, record: record);
    // Expected shape: { inserted: [{_id: ... , ...}], skipped: [] }
    final inserted = (res['inserted'] as List?) ?? const [];
    if (inserted.isEmpty) {
      throw Exception('Insert no retornó registros');
    }
    return _fromMap(inserted.first as Map<String, dynamic>);
  }

  @override
  Future<Course> updateCourse(Course course, {bool partial = true}) async {
    final token = await _requireToken();
    // Only send editable user-facing fields unless a full sync is explicitly requested.
    final updates = <String, dynamic>{
      'name': course.name,
      'description': course.description,
      if (!partial) 'join_code': course.joinCode,
      if (!partial) 'teacher_id': course.teacherId,
      if (!partial) 'is_active': course.isActive,
    };
    final res = await _service.updateCourse(
      accessToken: token,
      id: course.id,
      updates: updates,
    );
    final updated = (res['updated'] as List?)?.cast<Map<String, dynamic>>() ??
        (res['data'] is List
            ? (res['data'] as List).cast<Map<String, dynamic>>()
            : const <Map<String, dynamic>>[]);
    if (updated.isNotEmpty) {
      return _fromMap(updated.first);
    }
    // fallback: re-read
    final again = await getCourseById(course.id);
    if (again == null) throw Exception('No se pudo leer curso actualizado');
    return again;
  }

  @override
  Future<bool> deleteCourse(String courseId) async {
    final token = await _requireToken();
    await _service.updateCourse(
      accessToken: token,
      id: courseId,
      updates: {'is_active': false},
    );
    return true;
  }

  @override
  Future<Course> setCourseActive(String courseId, bool active) async {
    final token = await _requireToken();
    final res = await _service.updateCourse(
      accessToken: token,
      id: courseId,
      updates: {'is_active': active},
    );
    final updated = (res['data'] is Map<String, dynamic>)
        ? res['data'] as Map<String, dynamic>
        : (res['updated'] is List && (res['updated'] as List).isNotEmpty)
            ? (res['updated'] as List).first as Map<String, dynamic>
            : null;
    if (updated != null) {
      return _fromMap(updated);
    }
    final again = await getCourseById(courseId);
    if (again == null) {
      throw Exception('No se pudo actualizar estado del curso');
    }
    return again;
  }

  @override
  Future<List<Course>> searchCoursesByTitle(String title) async {
    // Not required for this task
    return [];
  }

  @override
  Future<Course?> getCourseByJoinCode(String joinCode) async {
    final token = await _requireToken();
    final rows = await _service.readCoursesByJoinCode(
        accessToken: token, joinCode: joinCode);
    final active = rows
        .where((m) => (m['is_active'] as bool?) ?? true)
        .toList(growable: false);
    if (active.isEmpty) return null;
    return _fromMap(active.first);
  }

  @override
  Future<List<Course>> getActiveCourses() async {
    // Not required for this task
    return [];
  }

  @override
  Future<List<Course>> getCoursesPaginated(
      {int page = 1,
      int limit = 10,
      String? categoryId,
      String? teacherId}) async {
    // Not required for this task
    return [];
  }

  @override
  Future<List<Course>> getCoursesOrdered() async {
    // Not required for this task
    return [];
  }

  @override
  Future<bool> updateCoursesOrder(List<String> courseIds) async {
    // Not required for this task
    return false;
  }
}
