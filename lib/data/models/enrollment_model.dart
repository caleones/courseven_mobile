import '../../domain/models/enrollment.dart';


class EnrollmentModel extends Enrollment {
  const EnrollmentModel({
    required super.id,
    required super.studentId,
    required super.courseId,
    required super.enrolledAt,
    super.isActive,
  });

  
  factory EnrollmentModel.fromJson(Map<String, dynamic> json) {
    return EnrollmentModel(
      id: json['_id'] as String,
      studentId: (json['user_id'] ?? json['student_id']) as String,
      courseId: json['course_id'] as String,
      enrolledAt: json['enrolled_at'] != null
          ? DateTime.parse(json['enrolled_at'] as String)
          : DateTime.now(),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      
      'user_id': studentId,
      'course_id': courseId,
      'enrolled_at': enrolledAt.toIso8601String(),
      'is_active': isActive,
    };
  }

  
  EnrollmentModel copyWith({
    String? id,
    String? studentId,
    String? courseId,
    DateTime? enrolledAt,
    bool? isActive,
  }) {
    return EnrollmentModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      courseId: courseId ?? this.courseId,
      enrolledAt: enrolledAt ?? this.enrolledAt,
      isActive: isActive ?? this.isActive,
    );
  }

  
  Enrollment toEntity() {
    return Enrollment(
      id: id,
      studentId: studentId,
      courseId: courseId,
      enrolledAt: enrolledAt,
      isActive: isActive,
    );
  }
}
