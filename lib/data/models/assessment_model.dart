import '../../domain/models/assessment.dart';


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
      reviewerId: json['reviewer'] as String,
      studentId: json['reviewed'] as String,
      punctualityScore: (json['punctuality_score'] as num).toInt(),
      contributionsScore: (json['contributions_score'] as num).toInt(),
      commitmentScore: (json['commitment_score'] as num).toInt(),
      attitudeScore: (json['attitude_score'] as num).toInt(),
      overallScorePersisted: _decodeOverall(json['overall_score']),
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
      'reviewer': reviewerId,
      'reviewed': studentId,
      'punctuality_score': punctualityScore,
      'contributions_score': contributionsScore,
      'commitment_score': commitmentScore,
      'attitude_score': attitudeScore,
      if (overallScorePersisted != null)
        'overall_score': _encodeOverall(overallScorePersisted!),
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

  static double? _decodeOverall(dynamic raw) {
    if (raw == null) return null;
    num? value;
    if (raw is num) {
      value = raw;
    } else {
      value = num.tryParse(raw.toString());
    }
    if (value == null) return null;
    final asDouble = value.toDouble();
    if (asDouble > 5) {
      final normalized = asDouble / 10;
      return double.parse(normalized.toStringAsFixed(1));
    }
    return double.parse(asDouble.toStringAsFixed(1));
  }

  static int _encodeOverall(double value) {
    final rounded = double.parse(value.toStringAsFixed(1));
    return (rounded * 10).round();
  }
}
