import '../../domain/models/group.dart';
import '../models/group_model.dart';
import '../../domain/repositories/group_repository.dart';
import '../services/roble_service.dart';

class GroupRepositoryImpl implements GroupRepository {
  final RobleService _service;
  final Future<String?> Function()? _getAccessToken;

  GroupRepositoryImpl(this._service,
      {Future<String?> Function()? getAccessToken})
      : _getAccessToken = getAccessToken;

  Future<String> _requireToken() async {
    if (_getAccessToken != null) {
      final t = await _getAccessToken!();
      if (t != null && t.isNotEmpty) return t;
    }
    throw Exception('Access token no disponible');
  }

  Group _fromMap(Map<String, dynamic> m) => GroupModel.fromJson(m).toEntity();

  Map<String, dynamic> _toRecord(Group g) => GroupModel(
        id: g.id,
        name: g.name,
        categoryId: g.categoryId,
        courseId: g.courseId,
        teacherId: g.teacherId,
        createdAt: g.createdAt,
        isActive: g.isActive,
      ).toJson();

  @override
  Future<Group> createGroup(Group group) async {
    final token = await _requireToken();
    final record = _toRecord(group);
    if (record['_id'] == null || (record['_id'] as String).isEmpty) {
      record.remove('_id');
    }
    final res = await _service.insertGroup(accessToken: token, record: record);
    final inserted = (res['inserted'] as List?) ?? const [];
    if (inserted.isEmpty) {
      throw Exception('Insert de grupo no retornó registros');
    }
    return _fromMap(inserted.first as Map<String, dynamic>);
  }

  @override
  Future<List<Group>> getGroupsByCategory(String categoryId) async {
    final token = await _requireToken();
    final rows = await _service.readGroups(
      accessToken: token,
      query: {'category_id': categoryId, 'is_active': 'true'},
    );
    return rows.map(_fromMap).toList(growable: false);
  }

  @override
  Future<List<Group>> getGroupsByCourse(String courseId) async {
    final token = await _requireToken();
    final rows = await _service.readGroups(
      accessToken: token,
      query: {'course_id': courseId, 'is_active': 'true'},
    );
    return rows.map(_fromMap).toList(growable: false);
  }

  @override
  Future<List<Group>> getGroupsByTeacher(String teacherId) async {
    final token = await _requireToken();
    final rows = await _service.readGroups(
      accessToken: token,
      query: {'teacher_id': teacherId, 'is_active': 'true'},
    );
    return rows.map(_fromMap).toList(growable: false);
  }

  // ==== Métodos no requeridos por ahora ====
  @override
  Future<bool> deleteGroup(String groupId) async {
    final token = await _requireToken();
    await _service.updateGroup(
      accessToken: token,
      id: groupId,
      updates: {'is_active': false},
    );
    return true;
  }

  @override
  Future<List<Group>> getActiveGroups() async {
    return [];
  }

  @override
  Future<Group?> getGroupById(String groupId) async {
    final token = await _requireToken();
    final rows = await _service.readGroups(
        accessToken: token, query: {'_id': groupId, 'is_active': 'true'});
    if (rows.isEmpty) return null;
    return _fromMap(rows.first);
  }

  @override
  Future<List<Group>> getGroupsPaginated(
      {int page = 1, int limit = 10, String? courseId}) async {
    return [];
  }

  @override
  Future<bool> isGroupNameAvailableInCourse(
      String name, String courseId) async {
    final token = await _requireToken();
    final rows = await _service.readGroups(accessToken: token, query: {
      'name': name,
      'course_id': courseId,
      'is_active': 'true',
    });
    return rows.isEmpty;
  }

  @override
  Future<Group> updateGroup(Group group) async {
    final token = await _requireToken();
    final updates = <String, dynamic>{
      'name': group.name,
      'category_id': group.categoryId,
      'course_id': group.courseId,
      'teacher_id': group.teacherId,
      'is_active': group.isActive,
    };
    final res = await _service.updateGroup(
      accessToken: token,
      id: group.id,
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
    final again = await getGroupById(group.id);
    if (again == null) throw Exception('No se pudo leer grupo actualizado');
    return again;
  }

  @override
  Future<List<Group>> searchGroupsByName(String name) async {
    final token = await _requireToken();
    final rows = await _service.readGroups(
        accessToken: token, query: {'name': name, 'is_active': 'true'});
    return rows.map(_fromMap).toList(growable: false);
  }
}
