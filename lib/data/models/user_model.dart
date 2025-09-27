import '../../domain/models/user.dart';


class UserModel extends User {
  const UserModel({
    required super.id,
    required super.studentId,
    required super.email,
    required super.firstName,
    required super.lastName,
    required super.username,
    required super.createdAt,
    super.isActive,
  });

  
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] as String,
      studentId: json['student_id'] as String,
      email: json['email'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      username: json['username'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'student_id': studentId,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'username': username,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive,
    };
  }

  
  UserModel copyWith({
    String? id,
    String? studentId,
    String? email,
    String? firstName,
    String? lastName,
    String? username,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return UserModel(
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

  
  User toEntity() {
    return User(
      id: id,
      studentId: studentId,
      email: email,
      firstName: firstName,
      lastName: lastName,
      username: username,
      createdAt: createdAt,
      isActive: isActive,
    );
  }
}
