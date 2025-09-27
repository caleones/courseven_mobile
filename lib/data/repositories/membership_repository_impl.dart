import '../../domain/models/membership.dart';
import '../models/membership_model.dart';
import '../../domain/repositories/membership_repository.dart';
import '../services/roble_service.dart';

class MembershipRepositoryImpl implements MembershipRepository {
  final RobleService _service;
  final Future<String?> Function()? _getAccessToken;

  MembershipRepositoryImpl(this._service,
      {Future<String?> Function()? getAccessToken})
      : _getAccessToken = getAccessToken;

  Future<String> _requireToken() async {
    if (_getAccessToken != null) {
      final t = await _getAccessToken!();
      if (t != null && t.isNotEmpty) return t;
    }
    throw Exception('Access token no disponible');
  }

  Membership _fromMap(Map<String, dynamic> m) =>
      MembershipModel.fromJson(m).toEntity();

  Map<String, dynamic> _toRecord(Membership m) => MembershipModel(
        id: m.id,
        userId: m.userId,
        groupId: m.groupId,
        joinedAt: m.joinedAt,
        isActive: m.isActive,
      ).toJson();

  @override
  Future<Membership?> getMembershipById(String membershipId) async {
    final token = await _requireToken();
    final rows = await _service
        .readMemberships(accessToken: token, query: {'_id': membershipId});
    if (rows.isEmpty) return null;
    return _fromMap(rows.first);
  }

  @override
  Future<List<Membership>> getMembershipsByUserId(String userId) async {
    final token = await _requireToken();
    final rows = await _service.readMemberships(accessToken: token, query: {
      'user_id': userId,
      'is_active': 'true',
    });
    return rows.map(_fromMap).toList(growable: false);
  }

  @override
  Future<List<Membership>> getMembershipsByGroupId(String groupId) async {
    final token = await _requireToken();
    final rows = await _service.readMemberships(accessToken: token, query: {
      'group_id': groupId,
      'is_active': 'true',
    });
    return rows.map(_fromMap).toList(growable: false);
  }

  @override
  Future<Membership> createMembership(Membership membership) async {
    final token = await _requireToken();
    final record = _toRecord(membership);
    if (record['_id'] == null || (record['_id'] as String).isEmpty) {
      record.remove('_id');
    }
    
    
    print(
        '[MembershipRepo] Creando membresía con record: ' + record.toString());
    final res =
        await _service.insertMembership(accessToken: token, record: record);
    
    print('[MembershipRepo] Respuesta insertMembership: ' + res.toString());
    final inserted = (res['inserted'] as List?) ?? const [];
    if (inserted.isEmpty) {
      final skipped = res['skipped'];
      final reason = skipped is List && skipped.isNotEmpty
          ? (skipped.first is Map &&
                  (skipped.first as Map).containsKey('reason')
              ? (skipped.first as Map)['reason']
              : 'Insert saltado sin razón provista')
          : 'Insert de membresía no retornó registros';
      throw Exception(reason);
    }
    return _fromMap(inserted.first as Map<String, dynamic>);
  }

  @override
  Future<Membership> updateMembership(Membership membership) async {
    
    throw UnimplementedError();
  }

  @override
  Future<bool> deleteMembership(String membershipId) async {
    
    return false;
  }

  @override
  Future<bool> isUserMemberOfGroup(String userId, String groupId) async {
    final token = await _requireToken();
    final rows = await _service.readMemberships(accessToken: token, query: {
      'user_id': userId,
      'group_id': groupId,
      'is_active': 'true',
    });
    return rows.isNotEmpty;
  }

  @override
  Future<List<Membership>> getActiveMemberships() async {
    final token = await _requireToken();
    final rows = await _service
        .readMemberships(accessToken: token, query: {'is_active': 'true'});
    return rows.map(_fromMap).toList(growable: false);
  }

  @override
  Future<List<Membership>> getMembershipsPaginated(
      {int page = 1, int limit = 10}) async {
    
    final token = await _requireToken();
    final rows = await _service.readMemberships(accessToken: token);
    return rows.map(_fromMap).toList(growable: false);
  }
}
