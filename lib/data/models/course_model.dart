import '../../domain/models/course.dart';

/// Modelo de datos para Course con serialización JSON
class CourseModel extends Course {
  const CourseModel({
    required super.id,
    required super.name,
    required super.description,
    required super.joinCode,
    required super.teacherId,
    required super.createdAt,
    super.isActive,
  });

  /// Crear CourseModel desde JSON
  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      joinCode: (json['join_code'] as String?) ?? '',
      teacherId: json['teacher_id'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  /// Convertir CourseModel a JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'join_code': joinCode,
      'teacher_id': teacherId,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive,
    };
  }

  /// Crear copia con cambios
  CourseModel copyWith({
    String? id,
    String? name,
    String? description,
    String? joinCode,
    String? teacherId,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return CourseModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      joinCode: joinCode ?? this.joinCode,
      teacherId: teacherId ?? this.teacherId,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Convertir a entidad de dominio
  Course toEntity() {
    return Course(
      id: id,
      name: name,
      description: description,
      joinCode: joinCode,
      teacherId: teacherId,
      createdAt: createdAt,
      isActive: isActive,
    );
  }
}
