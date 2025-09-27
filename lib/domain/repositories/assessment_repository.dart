import '../models/assessment.dart';
import '../models/peer_review_summaries.dart';

abstract class AssessmentRepository {
  
  Future<List<Assessment>> getAssessmentsByActivity(String activityId);
  Future<List<Assessment>> getAssessmentsByGroup(String groupId);
  Future<List<Assessment>> getAssessmentsByReviewer(
      String activityId, String reviewerId);
  Future<List<Assessment>> getAssessmentsReceivedByStudent(
      String activityId, String studentId);
  Future<Assessment> createAssessment(Assessment assessment);
  Future<bool> existsAssessment(
      {required String activityId,
      required String reviewerId,
      required String studentId});

  
  Future<List<Assessment>> getAssessmentsForStudentAcrossActivities(
      List<String> activityIds, String studentId);
  Future<List<String>> listPendingPeerIds({
    required String activityId,
    required String groupId,
    required String reviewerId,
    required List<String> groupMemberIds,
  });

  
  Future<ActivityPeerReviewSummary> computeActivitySummary(String activityId);
  Future<CoursePeerReviewSummary> computeCourseSummary(
      List<String> activityIds);
}
