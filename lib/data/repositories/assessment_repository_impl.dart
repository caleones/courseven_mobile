import '../../domain/models/assessment.dart';
import '../../domain/models/peer_review_summaries.dart';
import '../../domain/repositories/assessment_repository.dart';
import '../models/assessment_model.dart';
import '../services/roble_service.dart';

class AssessmentRepositoryImpl implements AssessmentRepository {
  final RobleService _service;
  final Future<String?> Function()? _getAccessToken;
  AssessmentRepositoryImpl(this._service,
      {Future<String?> Function()? getAccessToken})
      : _getAccessToken = getAccessToken;

  Future<String> _requireToken() async {
    if (_getAccessToken != null) {
      final t = await _getAccessToken!();
      if (t != null && t.isNotEmpty) return t;
    }
    throw Exception('Access token no disponible');
  }

  Assessment _fromMap(Map<String, dynamic> m) =>
      AssessmentModel.fromJson(m).toEntity();

  @override
  Future<List<Assessment>> getAssessmentsByActivity(String activityId) async {
    final token = await _requireToken();
    final rows = await _service.readTable(
        accessToken: token,
        table: 'assessments',
        query: {'activity_id': activityId});
    return rows.map(_fromMap).toList(growable: false);
  }

  @override
  Future<List<Assessment>> getAssessmentsByGroup(String groupId) async {
    final token = await _requireToken();
    final rows = await _service.readTable(
        accessToken: token, table: 'assessments', query: {'group_id': groupId});
    return rows.map(_fromMap).toList(growable: false);
  }

  @override
  Future<List<Assessment>> getAssessmentsByReviewer(
      String activityId, String reviewerId) async {
    final token = await _requireToken();
    final rows = await _service
        .readTable(accessToken: token, table: 'assessments', query: {
      'activity_id': activityId,
      'reviewer_id': reviewerId,
    });
    return rows.map(_fromMap).toList(growable: false);
  }

  @override
  Future<List<Assessment>> getAssessmentsReceivedByStudent(
      String activityId, String studentId) async {
    final token = await _requireToken();
    final rows = await _service
        .readTable(accessToken: token, table: 'assessments', query: {
      'activity_id': activityId,
      'student_id': studentId,
    });
    return rows.map(_fromMap).toList(growable: false);
  }

  @override
  Future<bool> existsAssessment(
      {required String activityId,
      required String reviewerId,
      required String studentId}) async {
    final token = await _requireToken();
    final rows = await _service
        .readTable(accessToken: token, table: 'assessments', query: {
      'activity_id': activityId,
      'reviewer_id': reviewerId,
      'student_id': studentId,
    });
    return rows.isNotEmpty;
  }

  @override
  Future<Assessment> createAssessment(Assessment assessment) async {
    final token = await _requireToken();
    final model = AssessmentModel(
      id: assessment.id,
      activityId: assessment.activityId,
      groupId: assessment.groupId,
      reviewerId: assessment.reviewerId,
      studentId: assessment.studentId,
      punctualityScore: assessment.punctualityScore,
      contributionsScore: assessment.contributionsScore,
      commitmentScore: assessment.commitmentScore,
      attitudeScore: assessment.attitudeScore,
      overallScorePersisted: assessment.overallScore,
      createdAt: assessment.createdAt,
      updatedAt: assessment.updatedAt,
    );
    final inserted = await _service.insertTable(
        accessToken: token, table: 'assessments', records: [model.toJson()]);
    final list = (inserted['inserted'] as List?) ??
        inserted['data'] as List? ??
        const [];
    if (list.isEmpty) throw Exception('Insert assessment sin retorno');
    return _fromMap(list.first as Map<String, dynamic>);
  }

  // ===== Extended helpers =====
  @override
  Future<List<Assessment>> getAssessmentsForStudentAcrossActivities(
      List<String> activityIds, String studentId) async {
    if (activityIds.isEmpty) return const [];
    final token = await _requireToken();
    // naive approach: multiple calls; could be optimized with backend support (IN query)
    final List<Assessment> all = [];
    for (final actId in activityIds) {
      final rows = await _service
          .readTable(accessToken: token, table: 'assessments', query: {
        'activity_id': actId,
        'student_id': studentId,
      });
      all.addAll(rows.map(_fromMap));
    }
    return all;
  }

  @override
  Future<List<String>> listPendingPeerIds({
    required String activityId,
    required String groupId,
    required String reviewerId,
    required List<String> groupMemberIds,
  }) async {
    // DEBUG OVERRIDE: incluir self para permitir auto-evaluación durante pruebas.
    // Lógica original (excluir self):
    // final peers = groupMemberIds.where((id) => id != reviewerId).toList();
    final peers = groupMemberIds.toList();
    if (peers.isEmpty) return const [];
    final existing = await getAssessmentsByReviewer(activityId, reviewerId);
    final doneIds = existing.map((a) => a.studentId).toSet();
    return peers.where((p) => !doneIds.contains(p)).toList(growable: false);
  }

  // ===== Aggregations =====
  @override
  Future<ActivityPeerReviewSummary> computeActivitySummary(
      String activityId) async {
    final assessments = await getAssessmentsByActivity(activityId);
    // group by groupId then by studentId (received)
    final Map<String, List<Assessment>> byGroup = {};
    for (final a in assessments) {
      byGroup.putIfAbsent(a.groupId, () => []).add(a);
    }
    final List<GroupActivityReviewStats> groupStats = [];
    for (final entry in byGroup.entries) {
      final groupAssessments = entry.value;
      final Map<String, List<Assessment>> byStudent = {};
      for (final a in groupAssessments) {
        byStudent.putIfAbsent(a.studentId, () => []).add(a);
      }
      final students = byStudent.entries.map((e) {
        final avgs = computeAverages(e.value);
        return StudentActivityReviewStats(
          studentId: e.key,
          receivedCount: e.value.length,
          averages: avgs,
        );
      }).toList(growable: false);
      final groupAvg = computeAverages(groupAssessments);
      groupStats.add(GroupActivityReviewStats(
        groupId: entry.key,
        averages: groupAvg,
        students: students,
      ));
    }
    final activityAvg = computeAverages(assessments);
    return ActivityPeerReviewSummary(
      activityId: activityId,
      activityAverages: activityAvg,
      groups: groupStats,
    );
  }

  @override
  Future<CoursePeerReviewSummary> computeCourseSummary(
      List<String> activityIds) async {
    if (activityIds.isEmpty) {
      return const CoursePeerReviewSummary(students: [], groups: []);
    }
    // Load all assessments per activity (sequentially for now)
    final Map<String, List<Assessment>> byActivity = {};
    for (final id in activityIds) {
      byActivity[id] = await getAssessmentsByActivity(id);
    }
    final allAssessments = byActivity.values.expand((l) => l).toList();
    // group by studentId (received)
    final Map<String, List<Assessment>> byStudent = {};
    for (final a in allAssessments) {
      byStudent.putIfAbsent(a.studentId, () => []).add(a);
    }
    final students = byStudent.entries.map((e) {
      final av = computeAverages(e.value);
      return StudentCrossActivityStats(
        studentId: e.key,
        assessmentsReceived: e.value.length,
        averages: av,
      );
    }).toList(growable: false);
    // group by groupId of evaluated student
    final Map<String, List<Assessment>> byGroup = {};
    for (final a in allAssessments) {
      byGroup.putIfAbsent(a.groupId, () => []).add(a);
    }
    final groups = byGroup.entries.map((e) {
      final av = computeAverages(e.value);
      return GroupCrossActivityStats(
        groupId: e.key,
        assessmentsCount: e.value.length,
        averages: av,
      );
    }).toList(growable: false);
    return CoursePeerReviewSummary(students: students, groups: groups);
  }
}
