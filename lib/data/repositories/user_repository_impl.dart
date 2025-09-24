import '../../domain/models/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../models/user_model.dart';
import '../services/roble_service.dart';

class UserRepositoryImpl implements UserRepository {
  final RobleService _service;
  final Future<String?> Function()? _getAccessToken;

  UserRepositoryImpl(this._service,
      {Future<String?> Function()? getAccessToken})
      : _getAccessToken = getAccessToken;

  Future<String> _requireToken() async {
    if (_getAccessToken != null) {
      final t = await _getAccessToken!();
      if (t != null && t.isNotEmpty) return t;
    }
    throw Exception('Access token no disponible');
  }

  User _fromMap(Map<String, dynamic> m) => UserModel.fromJson(m).toEntity();

  @override
  Future<User?> getUserById(String userId) async {
    final token = await _requireToken();
    final rows =
        await _service.readUsers(accessToken: token, query: {'_id': userId});
    if (rows.isEmpty) return null;
    return _fromMap(rows.first);
  }

  // ===== Stubs for not-yet-needed methods =====
  @override
  Future<User?> getUserByEmail(String email) async => null;

  @override
  Future<User?> getUserByStudentId(String studentId) async => null;

  @override
  Future<User?> getUserByUsername(String username) async => null;

  @override
  Future<User> createUser(User user) async => throw UnimplementedError();

  @override
  Future<User> updateUser(User user) async => throw UnimplementedError();

  @override
  Future<bool> deleteUser(String userId) async => throw UnimplementedError();

  @override
  Future<List<User>> searchUsersByName(String name) async => [];

  @override
  Future<List<User>> getUsersPaginated({int page = 1, int limit = 10}) async =>
      [];

  @override
  Future<bool> isEmailAvailable(String email) async => false;

  @override
  Future<bool> isStudentIdAvailable(String studentId) async => false;

  @override
  Future<bool> isUsernameAvailable(String username) async => false;

  @override
  bool isValidEmail(String email) => email.contains('@');

  @override
  bool isValidStudentId(String studentId) => studentId.isNotEmpty;

  @override
  bool isValidUsername(String username) => username.isNotEmpty;
}
