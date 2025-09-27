import '../models/user.dart';



abstract class UserRepository {
  
  
  Future<User?> getUserById(String userId);

  
  Future<User?> getUserByEmail(String email);

  
  Future<User?> getUserByStudentId(String studentId);

  
  Future<User?> getUserByUsername(String username);

  
  Future<User> createUser(User user);

  
  Future<User> updateUser(User user);

  
  Future<bool> deleteUser(String userId);

  
  
  Future<List<User>> searchUsersByName(String name);

  
  Future<List<User>> getUsersPaginated({
    int page = 1,
    int limit = 10,
  });

  
  
  Future<bool> isEmailAvailable(String email);

  
  Future<bool> isStudentIdAvailable(String studentId);

  
  Future<bool> isUsernameAvailable(String username);

  
  bool isValidEmail(String email);

  
  bool isValidStudentId(String studentId);

  
  bool isValidUsername(String username);
}
