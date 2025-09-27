import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/activity_controller.dart';
import '../../controllers/peer_review_controller.dart';
import '../../widgets/course/course_ui_components.dart';
import '../../theme/app_theme.dart';
import '../../../domain/models/assessment.dart';
import '../../../domain/models/peer_review_summaries.dart';

class StudentOwnPeerReviewResultsPage extends StatefulWidget {
  final String courseId;
  final String activityId;
  const StudentOwnPeerReviewResultsPage(
      {super.key, required this.courseId, required this.activityId});
  @override
  State<StudentOwnPeerReviewResultsPage> createState() =>
      _StudentOwnPeerReviewResultsPageState();
}

class _StudentOwnPeerReviewResultsPageState
    extends State<StudentOwnPeerReviewResultsPage> {
  final activityController = Get.find<ActivityController>();
  PeerReviewController? _peerReviewController;
  bool _requestedPeerData = false;

  @override
  void initState() {
    super.initState();
    try {
      _peerReviewController = Get.find<PeerReviewController>();
    } catch (_) {}
    if (widget.courseId.isNotEmpty) {
      activityController.loadForCourse(widget.courseId);
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
      final userId = pr?.currentUserId;
      if (pr == null || userId == null) {
        return const Scaffold(body: Center(child: Text('No disponible')));
      }
      if (!_requestedPeerData) {
        _requestedPeerData = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          pr.loadForActivity(activity);
        });
      }
      final canSee = pr.canStudentSeePublicResults(activity);
      if (!canSee) {
        return CoursePageScaffold(
          header: CourseHeader(
              title: activity.title,
              subtitle: 'Mis Resultados',
              showEdit: false),
          sections: const [
            SectionCard(
                title: 'Acceso Restringido',
                child: Text('Aún no puedes ver los resultados.')),
          ],
        );
      }
      final received =
          List<Assessment>.from(pr.assessmentsReceived(activity.id, userId))
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final summary = pr.activitySummary(activity.id);
      ScoreAverages? myGroupAvg;
      if (summary != null) {
        for (final g in summary.groups) {
          final hasStudent = g.students.any((s) => s.studentId == userId);
          if (hasStudent) {
            myGroupAvg = g.averages;
            break;
          }
        }
      }
      return CoursePageScaffold(
        header: CourseHeader(
            title: activity.title, subtitle: 'Mis Resultados', showEdit: false),
        sections: [
          _groupAverageSection(myGroupAvg),
          _receivedAssessmentsSection(received, activity.id),
        ],
      );
    });
  }

  Widget _groupAverageSection(ScoreAverages? avg) {
    if (avg == null) {
      return const SectionCard(
          title: 'Promedio del Grupo', child: Text('Sin datos aún'));
    }
    return SectionCard(
      title: 'Promedio del Grupo',
      leadingIcon: Icons.groups_2,
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

  Widget _receivedAssessmentsSection(
      List<Assessment> assessments, String activityId) {
    return SectionCard(
      title: 'Evaluaciones que Recibí (${assessments.length})',
      leadingIcon: Icons.inbox_outlined,
      child: assessments.isEmpty
          ? const Text('Aún no recibes evaluaciones')
          : ListView.builder(
              itemCount: assessments.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (ctx, i) {
                final a = assessments[i];
                return SolidListTile(
                  dense: true,
                  title: 'Evaluación ${i + 1}',
                  subtitle:
                      'Promedio ${a.overallScore.toStringAsFixed(1)} · P:${a.punctualityScore} C:${a.contributionsScore} Cm:${a.commitmentScore} A:${a.attitudeScore}',
                  trailing: const Icon(Icons.visibility, size: 18),
                  onTap: () {
                    Get.toNamed('/assessment-detail', arguments: {
                      'courseId': widget.courseId,
                      'activityId': activityId,
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
}
