import 'assessment.dart';

/// Average scores per criterion and overall.
class ScoreAverages {
  final double punctuality;
  final double contributions;
  final double commitment;
  final double attitude;
  final double overall;
  const ScoreAverages({
    required this.punctuality,
    required this.contributions,
    required this.commitment,
    required this.attitude,
    required this.overall,
  });
}

/// Per-student received averages for a single activity.
class StudentActivityReviewStats {
  final String studentId;
  final int receivedCount;
  final ScoreAverages averages;
  const StudentActivityReviewStats({
    required this.studentId,
    required this.receivedCount,
    required this.averages,
  });
}

/// Group-level stats for an activity (aggregated over its members' received assessments).
class GroupActivityReviewStats {
  final String groupId;
  final ScoreAverages averages; // group average
  final List<StudentActivityReviewStats> students; // per student detail
  const GroupActivityReviewStats({
    required this.groupId,
    required this.averages,
    required this.students,
  });
}

/// Summary for one activity including global average and per-group breakdown.
class ActivityPeerReviewSummary {
  final String activityId;
  final ScoreAverages activityAverages;
  final List<GroupActivityReviewStats> groups;
  const ActivityPeerReviewSummary({
    required this.activityId,
    required this.activityAverages,
    required this.groups,
  });
}

/// Cross-activity stats per student.
class StudentCrossActivityStats {
  final String studentId;
  final int assessmentsReceived;
  final ScoreAverages averages;
  const StudentCrossActivityStats({
    required this.studentId,
    required this.assessmentsReceived,
    required this.averages,
  });
}

/// Cross-activity stats per group.
class GroupCrossActivityStats {
  final String groupId;
  final int
      assessmentsCount; // total assessments whose evaluated student belonged to this group
  final ScoreAverages averages;
  const GroupCrossActivityStats({
    required this.groupId,
    required this.assessmentsCount,
    required this.averages,
  });
}

/// Course level summary across a set of activities (within same course).
class CoursePeerReviewSummary {
  final List<StudentCrossActivityStats> students;
  final List<GroupCrossActivityStats> groups;
  const CoursePeerReviewSummary({
    required this.students,
    required this.groups,
  });
}

// Utility functions (pure) to compute averages from assessments.
ScoreAverages computeAverages(List<Assessment> assessments) {
  if (assessments.isEmpty) {
    return const ScoreAverages(
        punctuality: 0,
        contributions: 0,
        commitment: 0,
        attitude: 0,
        overall: 0);
  }
  double sumP = 0, sumC = 0, sumCm = 0, sumA = 0, sumO = 0;
  for (final a in assessments) {
    sumP += a.punctualityScore;
    sumC += a.contributionsScore;
    sumCm += a.commitmentScore;
    sumA += a.attitudeScore;
    sumO += a.overallScore;
  }
  final n = assessments.length.toDouble();
  double r(double v) => double.parse((v / n).toStringAsFixed(2));
  return ScoreAverages(
    punctuality: r(sumP),
    contributions: r(sumC),
    commitment: r(sumCm),
    attitude: r(sumA),
    overall: r(sumO),
  );
}
