import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/activity_controller.dart';
import '../../controllers/course_controller.dart';
import '../../controllers/enrollment_controller.dart';
import '../../controllers/peer_review_controller.dart';
import '../../widgets/course/course_ui_components.dart';
import '../../theme/app_theme.dart';
import '../../../domain/models/course_activity.dart';
import '../../../domain/models/peer_review_summaries.dart';

class StudentCoursePeerResultsPage extends StatefulWidget {
  final String courseId;
  final String studentId;
  const StudentCoursePeerResultsPage(
      {super.key, required this.courseId, required this.studentId});

  @override
  State<StudentCoursePeerResultsPage> createState() =>
      _StudentCoursePeerResultsPageState();
}

class _StudentCoursePeerResultsPageState
    extends State<StudentCoursePeerResultsPage> {
  final activityController = Get.find<ActivityController>();
  final courseController = Get.find<CourseController>();
  final enrollmentController = Get.find<EnrollmentController>();
  final peerReviewController = Get.find<PeerReviewController>();

  bool _requestedSummary = false;

  @override
  void initState() {
    super.initState();
    if (widget.courseId.isNotEmpty) {
      courseController.getCourseById(widget.courseId);
      enrollmentController.loadEnrollmentsForCourse(widget.courseId);
      activityController.loadForCourse(widget.courseId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final activities =
          activityController.activitiesByCourse[widget.courseId] ?? const [];
      final reviewActivities = activities
          .where((a) => a.reviewing && !a.privateReview)
          .map((a) => a.id)
          .toList(growable: false);
      final isLoadingActivities = activityController.isLoading.value;

      if (!_requestedSummary && reviewActivities.isNotEmpty) {
        _requestedSummary = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          peerReviewController.loadCourseSummary(
            courseId: widget.courseId,
            activityIds: reviewActivities,
            force: true,
          );
        });
      }

      final summary = peerReviewController.courseSummary(widget.courseId);
      final studentStats = summary?.students
          .firstWhereOrNull((s) => s.studentId == widget.studentId);
      final name = enrollmentController.userName(widget.studentId);
      final course = courseController.coursesCache[widget.courseId];

      final activitiesCount = reviewActivities.length;

      final sections = _buildSections(
        activities: activities,
        reviewActivitiesCount: activitiesCount,
        isLoadingActivities: isLoadingActivities,
        summary: summary,
        studentStats: studentStats,
      );

      return CoursePageScaffold(
        header: CourseHeader(
          title: name,
          subtitle: course != null
              ? 'Resultados globales · ${course.name}'
              : 'Resultados de Peer Review',
          showEdit: false,
        ),
        sections: sections,
      );
    });
  }

  List<Widget> _buildSections({
    required List<CourseActivity> activities,
    required int reviewActivitiesCount,
    required bool isLoadingActivities,
    required CoursePeerReviewSummary? summary,
    required StudentCrossActivityStats? studentStats,
  }) {
    if (isLoadingActivities && activities.isEmpty) {
      return const [
        Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: CircularProgressIndicator(),
          ),
        ),
      ];
    }
    if (reviewActivitiesCount == 0) {
      return const [
        SectionCard(
          title: 'Sin resultados',
          child:
              Text('No hay actividades públicas de peer review en este curso.'),
        ),
      ];
    }
    if (summary == null) {
      return const [
        Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: CircularProgressIndicator(),
          ),
        ),
      ];
    }
    if (studentStats == null || studentStats.assessmentsReceived == 0) {
      return const [
        SectionCard(
          title: 'Sin evaluaciones recibidas',
          child: Text(
              'El estudiante aún no ha recibido evaluaciones en las actividades públicas.'),
        ),
      ];
    }
    return [
      _averagesCard(studentStats),
      _metaCard(studentStats, reviewActivitiesCount),
      _activitiesCard(activities),
    ];
  }

  Widget _averagesCard(StudentCrossActivityStats stats) {
    final avg = stats.averages;
    return SectionCard(
      title: 'Promedios recibidos (${stats.assessmentsReceived} evaluaciones)',
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

  Widget _metaCard(StudentCrossActivityStats stats, int activitiesCount) {
    return SectionCard(
      title: 'Resumen',
      leadingIcon: Icons.insights_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _kv('Evaluaciones recibidas', stats.assessmentsReceived.toString()),
          _kv('Actividades consideradas',
              activitiesCount > 0 ? activitiesCount.toString() : 'Sin datos'),
        ],
      ),
    );
  }

  Widget _activitiesCard(List<CourseActivity> activities) {
    final relevant =
        activities.where((a) => a.reviewing && !a.privateReview).toList();
    if (relevant.isEmpty) return const SizedBox.shrink();
    return SectionCard(
      title: 'Actividades consideradas (${relevant.length})',
      leadingIcon: Icons.list_alt,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: relevant
            .map((a) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(a.title),
                  subtitle: a.dueDate != null
                      ? Text('Cierre: ${_fmtDate(a.dueDate!)}')
                      : null,
                ))
            .toList(),
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

  Widget _kv(String key, String value) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(key,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: onSurface.withOpacity(.75))),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
