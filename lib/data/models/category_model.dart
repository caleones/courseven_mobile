import '../../domain/models/category.dart';


class CategoryModel extends Category {
  const CategoryModel({
    required super.id,
    required super.name,
    super.description,
    required super.courseId,
    required super.teacherId,
    required super.groupingMethod,
    super.maxMembersPerGroup,
    required super.createdAt,
    super.isActive,
  });

  
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      courseId: json['course_id'] as String,
      teacherId: json['teacher_id'] as String,
      groupingMethod: json['grouping_method'] as String,
      maxMembersPerGroup: json['max_members_per_group'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'course_id': courseId,
      'teacher_id': teacherId,
      'grouping_method': groupingMethod,
      'max_members_per_group': maxMembersPerGroup,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive,
    };
  }

  
  Category toEntity() {
    return Category(
      id: id,
      name: name,
      description: description,
      courseId: courseId,
      teacherId: teacherId,
      groupingMethod: groupingMethod,
      maxMembersPerGroup: maxMembersPerGroup,
      createdAt: createdAt,
      isActive: isActive,
    );
  }
}
