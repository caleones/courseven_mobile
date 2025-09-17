/// Entidad de dominio para representar un curso en el sistema CourSEVEN
class Course {
  final String id;
  final String title;
  final String description;
  final String categoryId;
  final String teacherId;
  final String? thumbnailUrl;
  final String? videoUrl;
  final int orderIndex;
  final DateTime createdAt;
  final bool isActive;

  const Course({
    required this.id,
    required this.title,
    required this.description,
    required this.categoryId,
    required this.teacherId,
    this.thumbnailUrl,
    this.videoUrl,
    required this.orderIndex,
    required this.createdAt,
    this.isActive = true,
  });

  /// Curso tiene miniatura
  bool get hasThumbnail => thumbnailUrl != null && thumbnailUrl!.isNotEmpty;

  /// Curso tiene video
  bool get hasVideo => videoUrl != null && videoUrl!.isNotEmpty;

  /// Curso está activo
  bool get isActiveCourse => isActive;

  /// Crear copia del curso con cambios
  Course copyWith({
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
    return Course(
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

  @override
  String toString() {
    return 'Course(id: $id, title: $title, categoryId: $categoryId, teacherId: $teacherId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Course &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.categoryId == categoryId &&
        other.teacherId == teacherId &&
        other.thumbnailUrl == thumbnailUrl &&
        other.videoUrl == videoUrl &&
        other.orderIndex == orderIndex &&
        other.createdAt == createdAt &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        description.hashCode ^
        categoryId.hashCode ^
        teacherId.hashCode ^
        thumbnailUrl.hashCode ^
        videoUrl.hashCode ^
        orderIndex.hashCode ^
        createdAt.hashCode ^
        isActive.hashCode;
  }
}
