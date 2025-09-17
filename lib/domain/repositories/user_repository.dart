import '../models/user.dart';

/// Repositorio abstracto para manejo de usuarios
/// Define el contrato que debe cumplir cualquier implementación de repositorio de usuarios
abstract class UserRepository {
  // CRUD básico de usuarios
  /// Obtener usuario por ID
  Future<User?> getUserById(String userId);

  /// Obtener usuario por email
  Future<User?> getUserByEmail(String email);

  /// Obtener usuario por student ID
  Future<User?> getUserByStudentId(String studentId);

  /// Obtener usuario por username
  Future<User?> getUserByUsername(String username);

  /// Crear nuevo usuario
  Future<User> createUser(User user);

  /// Actualizar usuario existente
  Future<User> updateUser(User user);

  /// Eliminar usuario (soft delete)
  Future<bool> deleteUser(String userId);

  // Búsquedas y filtros
  /// Buscar usuarios por nombre
  Future<List<User>> searchUsersByName(String name);

  /// Obtener usuarios paginados
  Future<List<User>> getUsersPaginated({
    int page = 1,
    int limit = 10,
  });

  // Validaciones
  /// Verificar si email está disponible
  Future<bool> isEmailAvailable(String email);

  /// Verificar si student ID está disponible
  Future<bool> isStudentIdAvailable(String studentId);

  /// Verificar si username está disponible
  Future<bool> isUsernameAvailable(String username);

  /// Validar formato de email
  bool isValidEmail(String email);

  /// Validar formato de student ID
  bool isValidStudentId(String studentId);

  /// Validar formato de username
  bool isValidUsername(String username);
}
