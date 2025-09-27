import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/activity_controller.dart';
import '../../controllers/enrollment_controller.dart';
import '../../controllers/group_controller.dart';
import '../../controllers/peer_review_controller.dart';
import '../../widgets/course/course_ui_components.dart';
import '../../theme/app_theme.dart';
import '../../../core/config/app_routes.dart';
import '../../../domain/models/peer_review_summaries.dart';

class StudentPeerReviewResultsPage extends StatefulWidget {
  final String courseId;
  final String activityId;
  final String groupId;
  final String studentId;
  const StudentPeerReviewResultsPage(
      {super.key,
      required this.courseId,
      required this.activityId,
      required this.groupId,
      required this.studentId});
  @override
  State<StudentPeerReviewResultsPage> createState() =>
      _StudentPeerReviewResultsPageState();
}

class _StudentPeerReviewResultsPageState
    extends State<StudentPeerReviewResultsPage> {
  final activityController = Get.find<ActivityController>();
  final enrollmentController = Get.find<EnrollmentController>();
  PeerReviewController? _peerReviewController;
  GroupController? _groupController;

  @override
  void initState() {
    super.initState();
    try {
      _peerReviewController = Get.find<PeerReviewController>();
    } catch (_) {}
    try {
      _groupController = Get.find<GroupController>();
    } catch (_) {}
    if (widget.courseId.isNotEmpty) {
      activityController.loadForCourse(widget.courseId);
      enrollmentController.loadEnrollmentsForCourse(widget.courseId);
      _groupController?.loadByCourse(widget.courseId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final activities =
          activityController.activitiesByCourse[widget.courseId] ?? [];
      final activity =
          activities.firstWhereOrNull((a) => a.id == widget.activityId);
      if (activity == null) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      final pr = _peerReviewController;
      final summary = pr?.activitySummary(activity.id);
      final group =
          summary?.groups.firstWhereOrNull((g) => g.groupId == widget.groupId);
      final studentStats = group?.students
          .firstWhereOrNull((s) => s.studentId == widget.studentId);
      final receivedAssessments =
          pr?.assessmentsReceived(activity.id, widget.studentId) ?? const [];

      final studentName = _userName(widget.studentId);
      final groupName = _groupName(widget.groupId);
      return CoursePageScaffold(
        header: CourseHeader(
          title: studentName,
          subtitle: groupName != null
              ? 'Peer Review · $groupName'
              : 'Resultados Peer Review',
          showEdit: false,
        ),
        sections: [
          _studentAveragesSection(studentStats),
          _receivedAssessmentsSection(receivedAssessments),
        ],
      );
    });
  }

  Widget _studentAveragesSection(StudentActivityReviewStats? stats) {
    if (stats == null) {
      return const SectionCard(
          title: 'Promedios', child: Text('Sin datos aún'));
    }
    final a = stats.averages;
    return SectionCard(
      title: 'Promedios del Estudiante (recibidos ${stats.receivedCount})',
      leadingIcon: Icons.person,
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          _metricPill('Overall', a.overall),
          _metricPill('Puntualidad', a.punctuality),
          _metricPill('Contribuciones', a.contributions),
          _metricPill('Compromiso', a.commitment),
          _metricPill('Actitud', a.attitude),
        ],
      ),
    );
  }

  Widget _receivedAssessmentsSection(List assessments) {
    return SectionCard(
      title: 'Evaluaciones Recibidas (${assessments.length})',
      leadingIcon: Icons.inbox,
      child: assessments.isEmpty
          ? const Text('Aún no tiene evaluaciones')
          : ListView.builder(
              itemCount: assessments.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (ctx, i) {
                final a = assessments[i];
                final reviewer = _userName(a.reviewerId);
                return SolidListTile(
                  dense: true,
                  title: 'De $reviewer',
                  subtitle:
                      'Overall ${a.overallScore.toStringAsFixed(1)}  P:${a.punctualityScore} C:${a.contributionsScore} Cm:${a.commitmentScore} A:${a.attitudeScore}',
                  trailing: const Icon(Icons.visibility, size: 18),
                  onTap: () {
                    Get.toNamed(AppRoutes.assessmentDetail, arguments: {
                      'courseId': widget.courseId,
                      'activityId': widget.activityId,
                      'assessmentId': a.id,
                    });
                  },
                );
              },
            ),
    );
  }

  Widget _metricPill(String label, double value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.goldAccent.withOpacity(.45)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: AppTheme.goldAccent.withOpacity(.95))),
          const SizedBox(height: 4),
          Text(value.toStringAsFixed(2),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              )),
        ],
      ),
    );
  }

  String _userName(String userId) {
    final name = enrollmentController.userName(userId);
    if (name.isNotEmpty && name != 'Estudiante') return name;
    final email = enrollmentController.userEmail(userId);
    return email.isNotEmpty ? email : userId;
  }

  String? _groupName(String groupId) {
    final groups =
        _groupController?.groupsByCourse[widget.courseId] ?? const [];
    final group = groups.firstWhereOrNull((g) => g.id == groupId);
    return group?.name;
  }
}
