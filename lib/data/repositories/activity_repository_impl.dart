import '../../domain/models/course_activity.dart';
import '../models/course_activity_model.dart';
import '../../domain/repositories/course_activity_repository.dart';
import '../services/roble_service.dart';

class CourseActivityRepositoryImpl implements CourseActivityRepository {
  final RobleService _service;
  final Future<String?> Function()? _getAccessToken;

  CourseActivityRepositoryImpl(this._service,
      {Future<String?> Function()? getAccessToken})
      : _getAccessToken = getAccessToken;

  Future<String> _requireToken() async {
    if (_getAccessToken != null) {
      final t = await _getAccessToken!();
      if (t != null && t.isNotEmpty) return t;
    }
    throw Exception('Access token no disponible');
  }

  CourseActivity _fromMap(Map<String, dynamic> m) =>
      CourseActivityModel.fromJson(m).toEntity();

  Map<String, dynamic> _toRecord(CourseActivity a) => CourseActivityModel(
        id: a.id,
        title: a.title,
        description: a.description,
        categoryId: a.categoryId,
        courseId: a.courseId,
        createdBy: a.createdBy,
        dueDate: a.dueDate,
        createdAt: a.createdAt,
        isActive: a.isActive,
        reviewing: a.reviewing,
        privateReview: a.privateReview,
      ).toJson();

  Future<CourseActivity?> getActivityById(String activityId) async {
    final token = await _requireToken();
    final rows = await _service.readActivities(
        accessToken: token, query: {'_id': activityId, 'is_active': 'true'});
    if (rows.isEmpty) return null;
    return _fromMap(rows.first);
  }

  Future<List<CourseActivity>> getActivitiesByCourse(String courseId) async {
    final token = await _requireToken();
    // DEBUG: quitar filtro is_active para asegurar visibilidad mientras se prueba peer review
    final rows = await _service
        .readActivities(accessToken: token, query: {'course_id': courseId});
    return rows.map(_fromMap).toList(growable: false);
  }

  Future<List<CourseActivity>> getActivitiesByCategory(
      String categoryId) async {
    final token = await _requireToken();
    final rows = await _service.readActivities(
        accessToken: token,
        query: {'category_id': categoryId, 'is_active': 'true'});
    return rows.map(_fromMap).toList(growable: false);
  }

  Future<CourseActivity> createActivity(CourseActivity activity) async {
    final token = await _requireToken();
    final record = _toRecord(activity);
    if (record['_id'] == null || (record['_id'] as String).isEmpty) {
      record.remove('_id');
    }
    final res =
        await _service.insertActivity(accessToken: token, record: record);
    final inserted = (res['inserted'] as List?) ?? const [];
    if (inserted.isEmpty) {
      throw Exception('Insert de actividad no retornó registros');
    }
    return _fromMap(inserted.first as Map<String, dynamic>);
  }

  @override
  Future<CourseActivity> updateActivity(CourseActivity activity) async {
    final token = await _requireToken();
    if (activity.id.isEmpty) {
      throw Exception('updateActivity requiere id');
    }
    // Build updates map from entity
    final updates = <String, dynamic>{
      'title': activity.title,
      'description': activity.description,
      'category_id': activity.categoryId,
      'course_id': activity.courseId,
      'created_by': activity.createdBy,
      if (activity.dueDate != null)
        'due_date': activity.dueDate!.toIso8601String(),
      'is_active': activity.isActive,
      'reviewing': activity.reviewing,
      'private_review': activity.privateReview,
    };
    final res = await _service.updateActivity(
      accessToken: token,
      id: activity.id,
      updates: updates,
    );
    // Some backends return updated records; if not, read it again
    final updated = (res['updated'] as List?)?.cast<Map<String, dynamic>>() ??
        (res['data'] is List
            ? (res['data'] as List).cast<Map<String, dynamic>>()
            : const <Map<String, dynamic>>[]);
    if (updated.isNotEmpty) {
      return _fromMap(updated.first);
    }
    // fallback: re-read
    final got = await getActivityById(activity.id);
    if (got == null) throw Exception('No se pudo leer actividad actualizada');
    return got;
  }

  @override
  Future<bool> deleteActivity(String activityId) async {
    final token = await _requireToken();
    await _service.updateActivity(
      accessToken: token,
      id: activityId,
      updates: {'is_active': false},
    );
    // Consider success if backend did not error
    return true;
  }
}
