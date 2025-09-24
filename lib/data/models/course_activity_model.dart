import '../../domain/models/course_activity.dart';

/// Modelo de datos para CourseActivity con serialización JSON
class CourseActivityModel extends CourseActivity {
  const CourseActivityModel({
    required super.id,
    required super.title,
    super.description,
    required super.categoryId,
    required super.courseId,
    required super.createdBy,
    super.dueDate,
    required super.createdAt,
    super.isActive,
    super.reviewing,
    super.privateReview,
  });

  factory CourseActivityModel.fromJson(Map<String, dynamic> json) {
    bool _parseBool(dynamic v, {bool defaultValue = true}) {
      if (v is bool) return v;
      if (v is String) {
        final lower = v.toLowerCase();
        if (lower == 'true' || lower == '1') return true;
        if (lower == 'false' || lower == '0') return false;
      }
      return defaultValue;
    }

    return CourseActivityModel(
      id: json['_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      categoryId: json['category_id'] as String,
      courseId: json['course_id'] as String,
      createdBy: json['created_by'] as String,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      isActive: _parseBool(json['is_active'], defaultValue: true),
      reviewing: _parseBool(json['reviewing'], defaultValue: false),
      privateReview: _parseBool(json['private_review'], defaultValue: true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'category_id': categoryId,
      'course_id': courseId,
      'created_by': createdBy,
      'due_date': dueDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive,
      'reviewing': reviewing,
      'private_review': privateReview,
    };
  }

  CourseActivity toEntity() => CourseActivity(
        id: id,
        title: title,
        description: description,
        categoryId: categoryId,
        courseId: courseId,
        createdBy: createdBy,
        dueDate: dueDate,
        createdAt: createdAt,
        isActive: isActive,
        reviewing: reviewing,
        privateReview: super.privateReview,
      );
}
