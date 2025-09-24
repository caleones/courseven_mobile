/// Entidad de dominio para representar una actividad asignada a una categoría
class CourseActivity {
  final String id;
  final String title;
  final String? description;
  final String categoryId;
  final String courseId;
  final String createdBy; // teacher id
  final DateTime? dueDate;
  final DateTime createdAt;
  final bool isActive;

  /// Indica si la actividad está en fase de peer review (habilitada por el profesor tras el due date)
  final bool reviewing;

  /// Visibilidad de los resultados del peer review para estudiantes: 'public' o 'private'
  final String peerVisibility; // values: 'public' | 'private'

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
    this.peerVisibility = 'private',
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
    String? peerVisibility,
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
      peerVisibility: peerVisibility ?? this.peerVisibility,
    );
  }
}
