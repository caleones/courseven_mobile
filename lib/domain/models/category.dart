
class Category {
  final String id;
  final String name;
  final String? description;
  final String courseId;
  final String teacherId;
  final String groupingMethod; 
  final int? maxMembersPerGroup;
  final DateTime createdAt;
  final bool isActive;

  const Category({
    required this.id,
    required this.name,
    this.description,
    required this.courseId,
    required this.teacherId,
    required this.groupingMethod,
    this.maxMembersPerGroup,
    required this.createdAt,
    this.isActive = true,
  });

  Category copyWith({
    String? id,
    String? name,
    String? description,
    String? courseId,
    String? teacherId,
    String? groupingMethod,
    int? maxMembersPerGroup,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      courseId: courseId ?? this.courseId,
      teacherId: teacherId ?? this.teacherId,
      groupingMethod: groupingMethod ?? this.groupingMethod,
      maxMembersPerGroup: maxMembersPerGroup ?? this.maxMembersPerGroup,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
