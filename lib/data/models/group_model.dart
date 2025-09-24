import '../../domain/models/group.dart';

/// Modelo de datos para Group con serialización JSON
class GroupModel extends Group {
  const GroupModel({
    required super.id,
    required super.name,
    required super.categoryId,
    required super.courseId,
    required super.teacherId,
    required super.createdAt,
    super.isActive,
  });

  /// Crear GroupModel desde JSON
  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['_id'] as String,
      name: json['name'] as String,
      categoryId: json['category_id'] as String,
      courseId: json['course_id'] as String,
      teacherId: json['teacher_id'] as String,
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
      'category_id': categoryId,
      'course_id': courseId,
      'teacher_id': teacherId,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive,
    };
  }

  /// Crear copia con cambios
  GroupModel copyWith({
    String? id,
    String? name,
    String? categoryId,
    String? courseId,
    String? teacherId,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      courseId: courseId ?? this.courseId,
      teacherId: teacherId ?? this.teacherId,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Convertir a entidad de dominio
  Group toEntity() {
    return Group(
      id: id,
      name: name,
      categoryId: categoryId,
      courseId: courseId,
      teacherId: teacherId,
      createdAt: createdAt,
      isActive: isActive,
    );
  }
}
