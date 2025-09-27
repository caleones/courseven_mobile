import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/activity_controller.dart';
import '../../controllers/enrollment_controller.dart';
import '../../controllers/group_controller.dart';
import '../../controllers/peer_review_controller.dart';
import '../../widgets/course/course_ui_components.dart';
import '../../theme/app_theme.dart';
import '../../../core/config/app_routes.dart';
import '../../../domain/models/course_activity.dart';
import '../../../domain/models/peer_review_summaries.dart';

class GroupPeerReviewResultsPage extends StatefulWidget {
  final String courseId;
  final String activityId;
  final String groupId;
  const GroupPeerReviewResultsPage(
      {super.key,
      required this.courseId,
      required this.activityId,
      required this.groupId});
  @override
  State<GroupPeerReviewResultsPage> createState() =>
      _GroupPeerReviewResultsPageState();
}

class _GroupPeerReviewResultsPageState
    extends State<GroupPeerReviewResultsPage> {
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
      final groupStats =
          summary?.groups.firstWhereOrNull((g) => g.groupId == widget.groupId);
      final groupAssessments =
          pr?.assessmentsForGroup(activity.id, widget.groupId) ?? const [];
      final groupName = _groupName(widget.groupId);
      return CoursePageScaffold(
        header: CourseHeader(
          title: groupName ?? widget.groupId,
          subtitle: 'Resultados Peer Review',
          showEdit: false,
        ),
        sections: [
          _groupAverageSection(groupStats),
          _studentsSection(activity, groupStats),
          _assessmentsSection(activity, groupAssessments),
        ],
      );
    });
  }

  Widget _groupAverageSection(GroupActivityReviewStats? groupStats) {
    if (groupStats == null) {
      return const SectionCard(
          title: 'Promedio del Grupo', child: Text('Sin datos todavía'));
    }
    final a = groupStats.averages;
    return SectionCard(
      title: 'Promedio del Grupo',
      leadingIcon: Icons.bar_chart,
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

  Widget _studentsSection(
      CourseActivity activity, GroupActivityReviewStats? groupStats) {
    if (groupStats == null) return const SizedBox.shrink();
    final students = groupStats.students;
    return SectionCard(
      title: 'Estudiantes (${students.length})',
      leadingIcon: Icons.people_alt,
      child: Column(
        children: students.map((s) {
          final av = s.averages;
          final name = _userName(s.studentId);
          return SolidListTile(
            title: name,
            subtitle:
                'Avg ${av.overall.toStringAsFixed(2)}  P:${av.punctuality.toStringAsFixed(1)} C:${av.contributions.toStringAsFixed(1)} Cm:${av.commitment.toStringAsFixed(1)} A:${av.attitude.toStringAsFixed(1)}',
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () {
              Get.toNamed(AppRoutes.studentPeerReviewResults, arguments: {
                'courseId': widget.courseId,
                'activityId': activity.id,
                'groupId': widget.groupId,
                'studentId': s.studentId,
              });
            },
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
          ? const Text('Sin evaluaciones')
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
