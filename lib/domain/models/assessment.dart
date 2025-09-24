/// Domain entity representing a single peer assessment (one reviewer -> one peer) for an activity within a group.
class Assessment {
  final String id;
  final String activityId;
  final String groupId;
  final String reviewerId; // who evaluates
  final String studentId; // evaluated peer
  final int punctualityScore; // 2,3,4,5
  final int contributionsScore; // 2,3,4,5
  final int commitmentScore; // 2,3,4,5
  final int attitudeScore; // 2,3,4,5
  final double?
      overallScorePersisted; // optional if backend stores overall_score
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Assessment({
    required this.id,
    required this.activityId,
    required this.groupId,
    required this.reviewerId,
    required this.studentId,
    required this.punctualityScore,
    required this.contributionsScore,
    required this.commitmentScore,
    required this.attitudeScore,
    this.overallScorePersisted,
    required this.createdAt,
    this.updatedAt,
  });

  /// Overall score: if persisted value exists, prefer it; else compute average of the four criteria.
  double get overallScore {
    if (overallScorePersisted != null) return overallScorePersisted!;
    final avg = (punctualityScore +
            contributionsScore +
            commitmentScore +
            attitudeScore) /
        4.0;
    return double.parse(avg.toStringAsFixed(1));
  }

  Assessment copyWith({
    String? id,
    String? activityId,
    String? groupId,
    String? reviewerId,
    String? studentId,
    int? punctualityScore,
    int? contributionsScore,
    int? commitmentScore,
    int? attitudeScore,
    double? overallScorePersisted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Assessment(
      id: id ?? this.id,
      activityId: activityId ?? this.activityId,
      groupId: groupId ?? this.groupId,
      reviewerId: reviewerId ?? this.reviewerId,
      studentId: studentId ?? this.studentId,
      punctualityScore: punctualityScore ?? this.punctualityScore,
      contributionsScore: contributionsScore ?? this.contributionsScore,
      commitmentScore: commitmentScore ?? this.commitmentScore,
      attitudeScore: attitudeScore ?? this.attitudeScore,
      overallScorePersisted:
          overallScorePersisted ?? this.overallScorePersisted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
