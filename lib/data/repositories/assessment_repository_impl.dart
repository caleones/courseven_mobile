import 'package:flutter/foundation.dart';
import '../../domain/models/assessment.dart';
import '../../domain/models/peer_review_summaries.dart';
import '../../domain/repositories/assessment_repository.dart';
import '../models/assessment_model.dart';
import '../services/roble_service.dart';

const String _assessmentsTable = 'assestments';

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

  Future<List<Map<String, dynamic>>> _readAssessments(
      Map<String, String> query) async {
    final token = await _requireToken();
    try {
      return await _service.readTable(
        accessToken: token,
        table: _assessmentsTable,
        query: query,
        suppressErrorLog: true,
      );
    } catch (e) {
      final message = e.toString();
      if (message.contains('DB read assessments failed: 500')) {
        debugPrint(
            '[ASSESSMENTS][READ] Backend devolvió 500 para query=$query, asumiendo lista vacía.');
        return const [];
      }
      rethrow;
    }
  }

  @override
  Future<List<Assessment>> getAssessmentsByActivity(String activityId) async {
    final rows = await _readAssessments({'activity_id': activityId});
    return rows.map(_fromMap).toList(growable: false);
  }

  @override
  Future<List<Assessment>> getAssessmentsByGroup(String groupId) async {
    final rows = await _readAssessments({'group_id': groupId});
    return rows.map(_fromMap).toList(growable: false);
  }

  @override
  Future<List<Assessment>> getAssessmentsByReviewer(
      String activityId, String reviewerId) async {
    final rows = await _readAssessments({
      'activity_id': activityId,
      'reviewer': reviewerId,
    });
    return rows.map(_fromMap).toList(growable: false);
  }

  @override
  Future<List<Assessment>> getAssessmentsReceivedByStudent(
      String activityId, String studentId) async {
    final rows = await _readAssessments({
      'activity_id': activityId,
      'reviewed': studentId,
    });
    return rows.map(_fromMap).toList(growable: false);
  }

  @override
  Future<bool> existsAssessment(
      {required String activityId,
      required String reviewerId,
      required String studentId}) async {
    final rows = await _readAssessments({
      'activity_id': activityId,
      'reviewer': reviewerId,
      'reviewed': studentId,
    });
    return rows.isNotEmpty;
  }

  @override
  Future<Assessment> createAssessment(Assessment assessment) async {
    final token = await _requireToken();
    final overallRounded =
        double.parse(assessment.overallScore.toStringAsFixed(1));
    final overallStored = (overallRounded * 10).round();

    final insertPayload = {
      'activity_id': assessment.activityId,
      'group_id': assessment.groupId,
      'reviewer': assessment.reviewerId,
      'reviewed': assessment.studentId,
      'punctuality_score': assessment.punctualityScore,
      'contributions_score': assessment.contributionsScore,
      'commitment_score': assessment.commitmentScore,
      'attitude_score': assessment.attitudeScore,
      'overall_score': overallStored,
    };
    debugPrint(
        '[ASSESSMENTS][CREATE] Insert payload: ' + insertPayload.toString());
    final response = await _service.insertTable(
      accessToken: token,
      table: _assessmentsTable,
      records: [insertPayload],
    );
    final list = (response['inserted'] as List?) ??
        response['data'] as List? ??
        const [];
    final skippedRaw = (response['skipped'] as List?) ?? const [];
    if (skippedRaw.isNotEmpty) {
      debugPrint('[ASSESSMENTS][CREATE] Skipped: $skippedRaw');
    }
    if (list.isEmpty) {
      final details =
          skippedRaw.isNotEmpty ? skippedRaw.toString() : response.toString();
      throw Exception('Insert assessment sin retorno: $details');
    }
    final raw = list.first as Map<String, dynamic>;
    debugPrint('[ASSESSMENTS][CREATE] Insert result raw: ' + raw.toString());
    final generatedId = raw['_id'] as String?;
    if (generatedId == null || generatedId.isEmpty) {
      debugPrint('[ASSESSMENTS][CREATE] WARNING: _id no retornado por backend');
    }
    final hasOverall =
        raw.containsKey('overall_score') && raw['overall_score'] != null;
    if (!hasOverall && generatedId != null && generatedId.isNotEmpty) {
      try {
        debugPrint(
            '[ASSESSMENTS][OVERALL][UPDATE] _id=$generatedId overall_score=$overallRounded (scaled=$overallStored)');
        await _service.updateRow(
          accessToken: token,
          table: _assessmentsTable,
          id: generatedId,
          updates: {'overall_score': overallStored},
        );
      } catch (e) {
        debugPrint(
            '[ASSESSMENTS][OVERALL][ERROR] Falló update overall_score: $e');
      }
    }
    final enriched = Map<String, dynamic>.from(raw);
    enriched['overall_score'] = enriched['overall_score'] ?? overallStored;
    enriched['activity_id'] = enriched['activity_id'] ?? assessment.activityId;
    enriched['group_id'] = enriched['group_id'] ?? assessment.groupId;
    enriched['reviewer'] = enriched['reviewer'] ?? assessment.reviewerId;
    enriched['reviewed'] = enriched['reviewed'] ?? assessment.studentId;
    enriched['punctuality_score'] =
        enriched['punctuality_score'] ?? assessment.punctualityScore;
    enriched['contributions_score'] =
        enriched['contributions_score'] ?? assessment.contributionsScore;
    enriched['commitment_score'] =
        enriched['commitment_score'] ?? assessment.commitmentScore;
    enriched['attitude_score'] =
        enriched['attitude_score'] ?? assessment.attitudeScore;
    enriched['created_at'] =
        enriched['created_at'] ?? assessment.createdAt.toIso8601String();
    return _fromMap(enriched);
  }

  
  @override
  Future<List<Assessment>> getAssessmentsForStudentAcrossActivities(
      List<String> activityIds, String studentId) async {
    if (activityIds.isEmpty) return const [];
    
    final List<Assessment> all = [];
    for (final actId in activityIds) {
      final rows = await _readAssessments({
        'activity_id': actId,
        'reviewed': studentId,
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
    
    
    
    final peers = groupMemberIds.toList();
    if (peers.isEmpty) return const [];
    final existing = await getAssessmentsByReviewer(activityId, reviewerId);
    final doneIds = existing.map((a) => a.studentId).toSet();
    return peers.where((p) => !doneIds.contains(p)).toList(growable: false);
  }

  
  @override
  Future<ActivityPeerReviewSummary> computeActivitySummary(
      String activityId) async {
    final assessments = await getAssessmentsByActivity(activityId);
    
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
    
    final Map<String, List<Assessment>> byActivity = {};
    for (final id in activityIds) {
      byActivity[id] = await getAssessmentsByActivity(id);
    }
    final allAssessments = byActivity.values.expand((l) => l).toList();
    
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
