import '../../domain/models/course.dart';

/// Modelo de datos para Course con serialización JSON
class CourseModel extends Course {
  const CourseModel({
    required super.id,
    required super.title,
    required super.description,
    required super.categoryId,
    required super.teacherId,
    super.thumbnailUrl,
    super.videoUrl,
    required super.orderIndex,
    required super.createdAt,
    super.isActive,
  });

  /// Crear CourseModel desde JSON
  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      categoryId: json['category_id'] as String,
      teacherId: json['teacher_id'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      videoUrl: json['video_url'] as String?,
      orderIndex: json['order_index'] as int,
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
      'title': title,
      'description': description,
      'category_id': categoryId,
      'teacher_id': teacherId,
      'thumbnail_url': thumbnailUrl,
      'video_url': videoUrl,
      'order_index': orderIndex,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive,
    };
  }

  /// Crear copia con cambios
  CourseModel copyWith({
    String? id,
    String? title,
    String? description,
    String? categoryId,
    String? teacherId,
    String? thumbnailUrl,
    String? videoUrl,
    int? orderIndex,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return CourseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      teacherId: teacherId ?? this.teacherId,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      orderIndex: orderIndex ?? this.orderIndex,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Convertir a entidad de dominio
  Course toEntity() {
    return Course(
      id: id,
      title: title,
      description: description,
      categoryId: categoryId,
      teacherId: teacherId,
      thumbnailUrl: thumbnailUrl,
      videoUrl: videoUrl,
      orderIndex: orderIndex,
      createdAt: createdAt,
      isActive: isActive,
    );
  }
}
