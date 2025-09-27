
class Enrollment {
  final String id;
  final String studentId;
  final String courseId;
  final DateTime enrolledAt;
  final bool isActive;

  const Enrollment({
    required this.id,
    required this.studentId,
    required this.courseId,
    required this.enrolledAt,
    this.isActive = true,
  });

  
  bool get isActiveEnrollment => isActive;

  
  Enrollment copyWith({
    String? id,
    String? studentId,
    String? courseId,
    DateTime? enrolledAt,
    bool? isActive,
  }) {
    return Enrollment(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      courseId: courseId ?? this.courseId,
      enrolledAt: enrolledAt ?? this.enrolledAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'Enrollment(id: $id, studentId: $studentId, courseId: $courseId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Enrollment &&
        other.id == id &&
        other.studentId == studentId &&
        other.courseId == courseId &&
        other.enrolledAt == enrolledAt &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        studentId.hashCode ^
        courseId.hashCode ^
        enrolledAt.hashCode ^
        isActive.hashCode;
  }
}
