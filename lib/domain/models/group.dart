
class Group {
  final String id;
  final String name;
  final String categoryId;
  final String courseId;
  final String teacherId;
  final DateTime createdAt;
  final bool isActive;

  const Group({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.courseId,
    required this.teacherId,
    required this.createdAt,
    this.isActive = true,
  });

  Group copyWith({
    String? id,
    String? name,
    String? categoryId,
    String? courseId,
    String? teacherId,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      courseId: courseId ?? this.courseId,
      teacherId: teacherId ?? this.teacherId,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}


