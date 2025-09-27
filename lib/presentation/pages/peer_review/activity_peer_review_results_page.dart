import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/config/app_routes.dart';
import '../../controllers/activity_controller.dart';
import '../../controllers/course_controller.dart';
import '../../controllers/enrollment_controller.dart';
import '../../controllers/group_controller.dart';
import '../../controllers/peer_review_controller.dart';
import '../../widgets/course/course_ui_components.dart';
import '../../theme/app_theme.dart';
import '../../../domain/models/course_activity.dart';
import '../../../domain/models/peer_review_summaries.dart';

class ActivityPeerReviewResultsPage extends StatefulWidget {
  final String courseId;
  final String activityId;
  const ActivityPeerReviewResultsPage(
      {super.key, required this.courseId, required this.activityId});

  @override
  State<ActivityPeerReviewResultsPage> createState() =>
      _ActivityPeerReviewResultsPageState();
}

class _ActivityPeerReviewResultsPageState
    extends State<ActivityPeerReviewResultsPage> {
  final activityController = Get.find<ActivityController>();
  final courseController = Get.find<CourseController>();
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
      final assessments = pr?.assessmentsForActivity(activity.id) ?? const [];

      return CoursePageScaffold(
        header: CourseHeader(
            title: activity.title,
            subtitle: 'Resultados Peer Review',
            showEdit: false),
        sections: [
          _activityAveragesCard(activity, summary),
          _groupsSection(activity, summary),
          _assessmentsSection(activity, assessments),
        ],
      );
    });
  }

  Widget _activityAveragesCard(
      CourseActivity activity, ActivityPeerReviewSummary? summary) {
    if (summary == null) {
      return const SectionCard(
          title: 'Promedio Actividad', child: Text('Aún no hay evaluaciones'));
    }
    final avg = summary.activityAverages;
    return SectionCard(
      title: 'Promedio Actividad',
      leadingIcon: Icons.bar_chart,
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          _metricPill('Overall', avg.overall),
          _metricPill('Puntualidad', avg.punctuality),
          _metricPill('Contribuciones', avg.contributions),
          _metricPill('Compromiso', avg.commitment),
          _metricPill('Actitud', avg.attitude),
        ],
      ),
    );
  }

  Widget _groupsSection(
      CourseActivity activity, ActivityPeerReviewSummary? summary) {
    if (summary == null) {
      return const SizedBox.shrink();
    }
    final groups = summary.groups;
    return SectionCard(
      title: 'Grupos (${groups.length})',
      leadingIcon: Icons.groups,
      child: Column(
        children: groups.map((g) {
          final name = _groupName(g.groupId);
          return SolidListTile(
            title: name ?? g.groupId,
            subtitle:
                'Avg ${g.averages.overall.toStringAsFixed(2)}  P:${g.averages.punctuality.toStringAsFixed(1)} C:${g.averages.contributions.toStringAsFixed(1)} Cm:${g.averages.commitment.toStringAsFixed(1)} A:${g.averages.attitude.toStringAsFixed(1)}',
            onTap: () {
              Get.toNamed(AppRoutes.groupPeerReviewResults, arguments: {
                'courseId': widget.courseId,
                'activityId': activity.id,
                'groupId': g.groupId,
              });
            },
            trailing: const Icon(Icons.chevron_right, size: 20),
          );
        }).toList(),
      ),
    );
  }

  Widget _assessmentsSection(CourseActivity activity, List assessments) {
    return SectionCard(
      title: 'Evaluaciones (${assessments.length})',
      leadingIcon: Icons.list_alt,
      child: assessments.isEmpty
          ? const Text('Sin evaluaciones todavía')
          : ListView.builder(
              itemCount: assessments.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (ctx, i) {
                final a = assessments[i];
                final reviewer = _userName(a.reviewerId);
                final evaluated = _userName(a.studentId);
                return SolidListTile(
                  dense: true,
                  title: '$reviewer → $evaluated',
                  subtitle:
                      'Overall ${a.overallScore.toStringAsFixed(1)}  P:${a.punctualityScore} C:${a.contributionsScore} Cm:${a.commitmentScore} A:${a.attitudeScore}',
                  trailing: const Icon(Icons.visibility, size: 18),
                  onTap: () {
                    Get.toNamed(AppRoutes.assessmentDetail, arguments: {
                      'courseId': widget.courseId,
                      'activityId': activity.id,
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

  String? _groupName(String groupId) {
    final groups =
        _groupController?.groupsByCourse[widget.courseId] ?? const [];
    final group = groups.firstWhereOrNull((g) => g.id == groupId);
    return group?.name;
  }

  String _userName(String userId) {
    final name = enrollmentController.userName(userId);
    if (name.isNotEmpty && name != 'Estudiante') return name;
    final email = enrollmentController.userEmail(userId);
    return email.isNotEmpty ? email : userId;
  }
}
