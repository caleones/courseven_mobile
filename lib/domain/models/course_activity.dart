
class CourseActivity {
  final String id;
  final String title;
  final String? description;
  final String categoryId;
  final String courseId;
  final String createdBy; 
  final DateTime? dueDate;
  final DateTime createdAt;
  final bool isActive;

  
  final bool reviewing;

  
  final bool privateReview;

  const CourseActivity({
    required this.id,
    required this.title,
    this.description,
    required this.categoryId,
    required this.courseId,
    required this.createdBy,
    this.dueDate,
    required this.createdAt,
    this.isActive = true,
    this.reviewing = false,
    this.privateReview = false,
  });

  CourseActivity copyWith({
    String? id,
    String? title,
    String? description,
    String? categoryId,
    String? courseId,
    String? createdBy,
    DateTime? dueDate,
    DateTime? createdAt,
    bool? isActive,
    bool? reviewing,
    bool? privateReview,
  }) {
    return CourseActivity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      courseId: courseId ?? this.courseId,
      createdBy: createdBy ?? this.createdBy,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      reviewing: reviewing ?? this.reviewing,
      privateReview: privateReview ?? this.privateReview,
    );
  }
}
