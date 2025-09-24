import '../../domain/models/assessment.dart';

/// Data model with JSON (Map) serialization for assessments table.
class AssessmentModel extends Assessment {
  const AssessmentModel({
    required super.id,
    required super.activityId,
    required super.groupId,
    required super.reviewerId,
    required super.studentId,
    required super.punctualityScore,
    required super.contributionsScore,
    required super.commitmentScore,
    required super.attitudeScore,
    super.overallScorePersisted,
    required super.createdAt,
    super.updatedAt,
  });

  factory AssessmentModel.fromJson(Map<String, dynamic> json) {
    return AssessmentModel(
      id: json['_id'] as String,
      activityId: json['activity_id'] as String,
      groupId: json['group_id'] as String,
      reviewerId: json['reviewer_id'] as String,
      studentId: json['student_id'] as String,
      punctualityScore: (json['punctuality_score'] as num).toInt(),
      contributionsScore: (json['contributions_score'] as num).toInt(),
      commitmentScore: (json['commitment_score'] as num).toInt(),
      attitudeScore: (json['attitude_score'] as num).toInt(),
      overallScorePersisted: json['overall_score'] == null
          ? null
          : (json['overall_score'] as num).toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'activity_id': activityId,
      'group_id': groupId,
      'reviewer_id': reviewerId,
      'student_id': studentId,
      'punctuality_score': punctualityScore,
      'contributions_score': contributionsScore,
      'commitment_score': commitmentScore,
      'attitude_score': attitudeScore,
      if (overallScorePersisted != null) 'overall_score': overallScorePersisted,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  Assessment toEntity() => Assessment(
        id: id,
        activityId: activityId,
        groupId: groupId,
        reviewerId: reviewerId,
        studentId: studentId,
        punctualityScore: punctualityScore,
        contributionsScore: contributionsScore,
        commitmentScore: commitmentScore,
        attitudeScore: attitudeScore,
        overallScorePersisted: overallScorePersisted,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
