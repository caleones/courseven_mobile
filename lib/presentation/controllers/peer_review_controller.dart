import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../../domain/models/assessment.dart';
import '../../domain/models/course_activity.dart';
import '../../domain/models/peer_review_summaries.dart';
import '../../domain/repositories/assessment_repository.dart';
import '../../domain/repositories/membership_repository.dart';
import '../../domain/repositories/group_repository.dart';
import 'auth_controller.dart';








class PeerReviewController extends GetxController {
  final AssessmentRepository _assessmentRepository;
  final MembershipRepository _membershipRepository;
  final GroupRepository _groupRepository;

  PeerReviewController(
    this._assessmentRepository,
    this._membershipRepository,
    this._groupRepository,
  );

  AuthController get _auth => Get.find<AuthController>();

  String? get currentUserId => _auth.currentUser?.id;

  
  final RxMap<String, List<Assessment>> _assessmentsByActivity =
      <String, List<Assessment>>{}.obs; 
  final RxMap<String, ActivityPeerReviewSummary> _activitySummaries =
      <String, ActivityPeerReviewSummary>{}.obs; 
  final RxMap<String, List<String>> _pendingPeersByActivity =
      <String, List<String>>{}
          .obs; 
  final RxMap<String, Map<String, int>> _progress =
      <String, Map<String, int>>{}.obs; 
  final RxMap<String, String> _groupIdByActivity =
      <String, String>{}.obs; 
  final RxMap<String, CoursePeerReviewSummary> _courseSummaries =
      <String, CoursePeerReviewSummary>{}
          .obs; 

  
  final RxMap<String, List<int>> _assessmentDurations =
      <String, List<int>>{}.obs; 
  final Map<String, DateTime> _enterEvaluateTimestamps =
      {}; 

  final isLoading = false.obs;
  final creating = false.obs;
  final errorMessage = ''.obs;

  
  final enablePeerReview = true.obs;

  

  
  Future<void> loadForActivity(CourseActivity activity,
      {String? groupId, List<String>? groupMemberIds}) async {
    if (!enablePeerReview.value) return;
    final userId = currentUserId;
    if (userId == null) return;
    
    if (!activity.reviewing) return;
    try {
      isLoading.value = true;
      
      List<Assessment> list = const [];
      try {
        list =
            await _assessmentRepository.getAssessmentsByActivity(activity.id);
      } catch (e) {
        debugPrint(
            '[PR][LOAD] Warning: fallo leyendo assessments activity=${activity.id}: $e');
      }
      _assessmentsByActivity[activity.id] = list;

      
      String? resolvedGroupId = groupId;
      List<String> members = groupMemberIds ?? [];
      if (resolvedGroupId == null || members.isEmpty) {
        
        
        final myMemberships =
            await _membershipRepository.getMembershipsByUserId(userId);
        debugPrint('[PR][LOAD] myMemberships count=${myMemberships.length}');
        final myGroupIds = myMemberships.map((m) => m.groupId).toSet();
        final catGroups =
            await _groupRepository.getGroupsByCategory(activity.categoryId);
        debugPrint('[PR][LOAD] catGroups count=${catGroups.length}');
        String? foundId;
        for (final g in catGroups) {
          if (g.courseId == activity.courseId && myGroupIds.contains(g.id)) {
            foundId = g.id;
            break;
          }
        }
        
        if (foundId == null) {
          for (final g in catGroups) {
            final ok =
                await _membershipRepository.isUserMemberOfGroup(userId, g.id);
            if (ok) {
              foundId = g.id;
              break;
            }
          }
          debugPrint('[PR][LOAD] fallback isUserMemberOfGroup found=$foundId');
        }
        resolvedGroupId = foundId;
        if (resolvedGroupId != null) {
          final memberships = await _membershipRepository
              .getMembershipsByGroupId(resolvedGroupId);
          members = memberships.map((m) => m.userId).toList();
        }
      }

      
      debugPrint(
          '[PR][LOAD] resolvedGroupId=$resolvedGroupId members=${members.length}');
      if (resolvedGroupId == null || members.length <= 1) {
        _pendingPeersByActivity[activity.id] = const [];
        _progress[activity.id] = {'done': 0, 'total': 0};
        _groupIdByActivity.remove(activity.id);
        await _refreshSummary(activity.id);
        return;
      }

      _groupIdByActivity[activity.id] = resolvedGroupId;

      
      List<String> pending = const [];
      try {
        pending = await _assessmentRepository.listPendingPeerIds(
          activityId: activity.id,
          groupId: resolvedGroupId,
          reviewerId: userId,
          groupMemberIds: members,
        );
      } catch (e) {
        debugPrint('[PR][LOAD] Warning: fallo listPendingPeerIds: $e');
        pending = members; 
      }
      
      final filteredPending = pending.where((p) => p != userId).toList();
      _pendingPeersByActivity[activity.id] = filteredPending;

      final existingMine = list.where((a) => a.reviewerId == userId).toList();
      
      final totalNeeded = (members.length - 1).clamp(0, 9999);
      _progress[activity.id] = {
        'done': existingMine.length,
        'total': totalNeeded,
      };

      
      await _refreshSummary(activity.id, force: true);
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
      update();
    }
  }

  
  Future<Assessment?> createAssessment({
    required CourseActivity activity,
    required String groupId,
    required String studentId, 
    required int punctuality,
    required int contributions,
    required int commitment,
    required int attitude,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      errorMessage.value = 'Usuario no autenticado';
      return null;
    }
    if (!activity.reviewing) {
      errorMessage.value = 'La actividad no está en peer review';
      return null;
    }
    try {
      creating.value = true;
      debugPrint(
          '[PR][CREATE] start reviewer=$userId -> student=$studentId activity=${activity.id}');
      if (studentId == userId) {
        errorMessage.value = 'No puedes auto-evaluarte';
        return null;
      }
      final already = await _assessmentRepository.existsAssessment(
        activityId: activity.id,
        reviewerId: userId,
        studentId: studentId,
      );
      if (already) {
        errorMessage.value = 'Ya evaluaste a este compañero';
        debugPrint(
            '[PR][CREATE] duplicate detected reviewer=$userId student=$studentId');
        return null;
      }
      final now = DateTime.now();
      final avg = ((punctuality + contributions + commitment + attitude) / 4.0);
      final overallRounded = double.parse(avg.toStringAsFixed(1));
      final assessment = Assessment(
        id: '',
        activityId: activity.id,
        groupId: groupId,
        reviewerId: userId,
        studentId: studentId,
        punctualityScore: punctuality,
        contributionsScore: contributions,
        commitmentScore: commitment,
        attitudeScore: attitude,
        overallScorePersisted: overallRounded,
        createdAt: now,
        updatedAt: null,
      );
      final created = await _assessmentRepository.createAssessment(assessment);
      debugPrint(
          '[PR][CREATE] created id=${created.id} overall=${created.overallScore}');
      
      final list = _assessmentsByActivity[activity.id] ?? [];
      _assessmentsByActivity[activity.id] = [...list, created];
      final currentPending =
          List<String>.from(_pendingPeersByActivity[activity.id] ?? const []);
      if (currentPending.remove(studentId)) {
        _pendingPeersByActivity[activity.id] = currentPending;
      }
      
      final members = await _getGroupMemberIds(groupId);
      final completedAssessments = _assessmentsByActivity[activity.id]!
          .where((a) => a.reviewerId == userId)
          .toList(growable: false);
      final completedIds = completedAssessments.map((a) => a.studentId).toSet();
      final totalNeeded = (members.length - 1).clamp(0, 9999);
      final pendingLocal = members
          .where((memberId) =>
              memberId != userId && !completedIds.contains(memberId))
          .toList(growable: false);
      _pendingPeersByActivity[activity.id] = pendingLocal;
      _progress[activity.id] = {
        'done': completedIds.length,
        'total': totalNeeded,
      };
      await _refreshSummary(activity.id, force: true);
      debugPrint(
          '[PR][SUMMARY] refreshed after create activity=${activity.id}');
      return created;
    } catch (e) {
      errorMessage.value = e.toString();
      debugPrint('[PR][CREATE][ERROR] $e');
      return null;
    } finally {
      creating.value = false;
      update();
    }
  }

  
  Future<List<String>> _getGroupMemberIds(String groupId) async {
    final memberships =
        await _membershipRepository.getMembershipsByGroupId(groupId);
    return memberships.map((m) => m.userId).toList(growable: false);
  }

  
  Future<void> _refreshSummary(String activityId, {bool force = false}) async {
    if (!force && _activitySummaries.containsKey(activityId)) return;
    try {
      debugPrint('[PR][SUMMARY] computing activity=$activityId');
      final summary =
          await _assessmentRepository.computeActivitySummary(activityId);
      _activitySummaries[activityId] = summary;
      debugPrint(
          '[PR][SUMMARY] stored activity=$activityId groups=${summary.groups.length}');
    } catch (e) {
      debugPrint('[PR][SUMMARY][ERROR] $e');
    }
  }

  
  List<Assessment> assessmentsForActivity(String activityId) =>
      _assessmentsByActivity[activityId] ?? const [];

  
  List<Assessment> assessmentsForGroup(String activityId, String groupId) {
    return assessmentsForActivity(activityId)
        .where((a) => a.groupId == groupId)
        .toList(growable: false);
  }

  
  List<Assessment> assessmentsReceived(String activityId, String studentId) {
    return assessmentsForActivity(activityId)
        .where((a) => a.studentId == studentId)
        .toList(growable: false);
  }

  
  ScoreAverages? groupAverages(String activityId, String groupId) {
    final summary = _activitySummaries[activityId];
    if (summary == null) return null;
    return summary.groups
        .firstWhereOrNull((g) => g.groupId == groupId)
        ?.averages;
  }

  
  List<StudentActivityReviewStats> groupStudentStats(
      String activityId, String groupId) {
    final summary = _activitySummaries[activityId];
    if (summary == null) return const [];
    final g = summary.groups.firstWhereOrNull((gr) => gr.groupId == groupId);
    return g?.students ?? const [];
  }

  ActivityPeerReviewSummary? activitySummary(String activityId) =>
      _activitySummaries[activityId];

  CoursePeerReviewSummary? courseSummary(String courseId) =>
      _courseSummaries[courseId];

  List<String> pendingPeers(String activityId) =>
      _pendingPeersByActivity[activityId] ?? const [];

  Map<String, int> progressFor(String activityId) =>
      _progress[activityId] ?? const {'done': 0, 'total': 0};

  String? groupIdFor(String activityId) => _groupIdByActivity[activityId];

  bool isCompleted(String activityId) {
    final p = progressFor(activityId);
    return p['total'] != null && p['total']! > 0 && p['done'] == p['total'];
  }

  
  bool canStudentReview(CourseActivity activity,
      {required bool isMemberOfGroup}) {
    if (!enablePeerReview.value) return false;
    if (!activity.reviewing) return false;
    if (!isMemberOfGroup) return false;
    
    
    
    
    
    return true;
  }

  
  bool canStudentSeePublicResults(CourseActivity activity) {
    return !activity.privateReview;
  }

  
  bool canTeacherSeeSummary(CourseActivity activity, String teacherId) {
    return activity.createdBy == teacherId ||
        true; 
  }

  
  void invalidateActivity(String activityId) {
    _activitySummaries.remove(activityId);
    _pendingPeersByActivity.remove(activityId);
    _progress.remove(activityId);
    _groupIdByActivity.remove(activityId);
  }

  
  Future<CoursePeerReviewSummary?> loadCourseSummary(
      {required String courseId,
      required List<String> activityIds,
      bool force = false}) async {
    if (!force && _courseSummaries.containsKey(courseId))
      return _courseSummaries[courseId];
    if (activityIds.isEmpty) return null;
    try {
      isLoading.value = true;
      final summary =
          await _assessmentRepository.computeCourseSummary(activityIds);
      _courseSummaries[courseId] = summary;
      return summary;
    } catch (e) {
      errorMessage.value = e.toString();
      return null;
    } finally {
      isLoading.value = false;
      update();
    }
  }

  
  void markEnterEvaluate(String activityId, String peerId) {
    _enterEvaluateTimestamps['$activityId|$peerId'] = DateTime.now();
  }

  void markFinishEvaluate(String activityId, String peerId) {
    final key = '$activityId|$peerId';
    final start = _enterEvaluateTimestamps.remove(key);
    if (start != null) {
      final dur = DateTime.now().difference(start).inSeconds;
      final list = _assessmentDurations[activityId] ?? [];
      _assessmentDurations[activityId] = [...list, dur];
    }
  }

  double averageEvaluationDuration(String activityId) {
    final list = _assessmentDurations[activityId];
    if (list == null || list.isEmpty) return 0;
    return list.reduce((a, b) => a + b) / list.length;
  }
}
