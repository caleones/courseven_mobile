/// Entidad de dominio para representar un usuario universal del sistema CourSEVEN
/// Un usuario puede ser simultáneamente estudiante y profesor según sus acciones
class User {
  final String id;
  final String studentId;
  final String email;
  final String firstName;
  final String lastName;
  final String username;
  final DateTime createdAt;
  final bool isActive;

  const User({
    required this.id,
    required this.studentId,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.createdAt,
    this.isActive = true,
  });

  /// Nombre completo del usuario
  String get fullName => '$firstName $lastName';

  /// Iniciales del usuario (para avatares)
  String get initials {
    final firstInitial = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final lastInitial = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$firstInitial$lastInitial';
  }

  /// Usuario está activo
  bool get isActiveUser => isActive;

  /// Crear copia del usuario con cambios
  User copyWith({
    String? id,
    String? studentId,
    String? email,
    String? firstName,
    String? lastName,
    String? username,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return User(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, studentId: $studentId, email: $email, fullName: $fullName, username: $username)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is User &&
        other.id == id &&
        other.studentId == studentId &&
        other.email == email &&
        other.firstName == firstName &&
        other.lastName == lastName &&
        other.username == username &&
        other.createdAt == createdAt &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        studentId.hashCode ^
        email.hashCode ^
        firstName.hashCode ^
        lastName.hashCode ^
        username.hashCode ^
        createdAt.hashCode ^
        isActive.hashCode;
  }
}
