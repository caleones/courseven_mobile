import '../../domain/models/group.dart';

/// Modelo de datos para Group con serialización JSON
class GroupModel extends Group {
  const GroupModel({
    required super.id,
    required super.name,
    super.description,
    required super.courseId,
    required super.createdAt,
    super.isActive,
  });

  /// Crear GroupModel desde JSON
  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      courseId: json['course_id'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  /// Convertir GroupModel a JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'course_id': courseId,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive,
    };
  }

  /// Crear copia con cambios
  GroupModel copyWith({
    String? id,
    String? name,
    String? description,
    String? courseId,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      courseId: courseId ?? this.courseId,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Convertir a entidad de dominio
  Group toEntity() {
    return Group(
      id: id,
      name: name,
      description: description,
      courseId: courseId,
      createdAt: createdAt,
      isActive: isActive,
    );
  }
}
