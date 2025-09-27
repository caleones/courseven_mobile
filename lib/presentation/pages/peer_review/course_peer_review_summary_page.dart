import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/config/app_routes.dart';
import '../../../domain/models/course_activity.dart';
import '../../../domain/models/group.dart';
import '../../../domain/models/peer_review_summaries.dart';
import '../../controllers/activity_controller.dart';
import '../../controllers/course_controller.dart';
import '../../controllers/enrollment_controller.dart';
import '../../controllers/group_controller.dart';
import '../../controllers/peer_review_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/course/course_ui_components.dart';

class CoursePeerReviewSummaryPage extends StatefulWidget {
  final String courseId;
  final List<String> activityIds;
  const CoursePeerReviewSummaryPage(
      {super.key, required this.courseId, required this.activityIds});

  @override
  State<CoursePeerReviewSummaryPage> createState() =>
      _CoursePeerReviewSummaryPageState();
}

class _CoursePeerReviewSummaryPageState
    extends State<CoursePeerReviewSummaryPage> {
  final peerReviewController = Get.find<PeerReviewController>();
  final activityController = Get.find<ActivityController>();
  final courseController = Get.find<CourseController>();
  final groupController = Get.find<GroupController>();
  final enrollmentController = Get.find<EnrollmentController>();

  bool _requestedSummary = false;

  @override
  void initState() {
    super.initState();
    if (widget.courseId.isNotEmpty) {
      courseController.getCourseById(widget.courseId);
      groupController.loadByCourse(widget.courseId);
      enrollmentController.loadEnrollmentsForCourse(widget.courseId);
      if (widget.activityIds.isEmpty) {
        activityController.loadForCourse(widget.courseId);
      }
    }
    if (widget.activityIds.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        peerReviewController.loadCourseSummary(
          courseId: widget.courseId,
          activityIds: widget.activityIds,
        );
      });
      _requestedSummary = true;
    }
  }

  List<String> _currentActivityIds() {
    if (widget.activityIds.isNotEmpty) return widget.activityIds;
    final activities = activityController.activitiesByCourse[widget.courseId] ??
        const <CourseActivity>[];
    return activities
        .where((a) => a.reviewing && !a.privateReview)
        .map((a) => a.id)
        .toList(growable: false);
  }

  Future<void> _refresh(List<String> activityIds) async {
    final ids = activityIds.isNotEmpty ? activityIds : _currentActivityIds();
    if (ids.isEmpty) return;
    await peerReviewController.loadCourseSummary(
      courseId: widget.courseId,
      activityIds: ids,
      force: true,
    );
    if (widget.activityIds.isEmpty) {
      await activityController.loadForCourse(widget.courseId);
    }
    await groupController.loadByCourse(widget.courseId);
    await enrollmentController.loadEnrollmentsForCourse(widget.courseId,
        force: true);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final activities =
          activityController.activitiesByCourse[widget.courseId] ??
              const <CourseActivity>[];
      final reviewActivityIds = widget.activityIds.isNotEmpty
          ? widget.activityIds
          : _currentActivityIds();
      if (!_requestedSummary && reviewActivityIds.isNotEmpty) {
        _requestedSummary = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          peerReviewController.loadCourseSummary(
            courseId: widget.courseId,
            activityIds: reviewActivityIds,
            force: true,
          );
        });
      }

      final error = peerReviewController.errorMessage.value;
      final summary = peerReviewController.courseSummary(widget.courseId);
      final course = courseController.coursesCache[widget.courseId];
      final groups =
          groupController.groupsByCourse[widget.courseId] ?? const <Group>[];

      final sections = error.isNotEmpty
          ? [
              SectionCard(
                title: 'Error al cargar',
                leadingIcon: Icons.error_outline,
                child: Text(
                  error,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ]
          : _buildSections(
              activityIds: reviewActivityIds,
              activities: activities,
              summary: summary,
              groups: groups,
            );

      return CoursePageScaffold(
        header: CourseHeader(
          title: course?.name ?? 'Curso',
          subtitle: 'Resultados globales de peer review',
          showEdit: false,
        ),
        sections: sections,
        onRefresh: () => _refresh(reviewActivityIds),
      );
    });
  }

  List<Widget> _buildSections({
    required List<String> activityIds,
    required List<CourseActivity> activities,
    required CoursePeerReviewSummary? summary,
    required List<Group> groups,
  }) {
    if (activityIds.isEmpty) {
      return [
        SectionCard(
          title: 'Sin actividades con peer review',
          leadingIcon: Icons.info_outline,
          child: const Text(
              'Configura actividades públicas de peer review para ver resultados a nivel curso.'),
        ),
      ];
    }
    if (summary == null) {
      if (peerReviewController.isLoading.value) {
        return const [
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: CircularProgressIndicator(),
            ),
          ),
        ];
      }
      return [
        SectionCard(
          title: 'Sin evaluaciones registradas',
          leadingIcon: Icons.info_outline,
          child: const Text(
              'Aún no hay evaluaciones registradas para las actividades consideradas.'),
        ),
      ];
    }

    final sections = <Widget>[];
    final totalAssessments =
        summary.groups.fold<int>(0, (acc, g) => acc + g.assessmentsCount);
    final weightedAverage = _weightedAverage(summary.groups);

    if (weightedAverage != null) {
      sections.add(_overviewCard(
        averages: weightedAverage,
        totalAssessments: totalAssessments,
        groupCount: summary.groups.length,
        studentCount: summary.students.length,
        activityCount: activityIds.length,
      ));
    }

    sections.add(_groupsCard(
      groupStats: summary.groups,
      groups: groups,
      activityIds: activityIds,
    ));

    final considered = activities
        .where((a) => activityIds.contains(a.id))
        .toList(growable: false);
    if (considered.isNotEmpty) {
      sections.add(_activitiesSection(considered));
    }

    return sections;
  }

  Widget _overviewCard({
    required ScoreAverages averages,
    required int totalAssessments,
    required int groupCount,
    required int studentCount,
    required int activityCount,
  }) {
    return SectionCard(
      title: 'Panorama general',
      leadingIcon: Icons.insights,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _metricChip('Overall', averages.overall),
              _metricChip('Puntualidad', averages.punctuality),
              _metricChip('Contribuciones', averages.contributions),
              _metricChip('Compromiso', averages.commitment),
              _metricChip('Actitud', averages.attitude),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _infoChip('Evaluaciones', totalAssessments.toString()),
              _infoChip('Grupos', groupCount.toString()),
              _infoChip('Estudiantes', studentCount.toString()),
              _infoChip('Actividades', activityCount.toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _groupsCard({
    required List<GroupCrossActivityStats> groupStats,
    required List<Group> groups,
    required List<String> activityIds,
  }) {
    if (groupStats.isEmpty) {
      return SectionCard(
        title: 'Grupos',
        leadingIcon: Icons.groups,
        child: const Text('No hay resultados disponibles por grupo todavía.'),
      );
    }
    final nameById = {for (final g in groups) g.id: g.name};
    return SectionCard(
      title: 'Grupos (${groupStats.length})',
      leadingIcon: Icons.groups,
      child: Column(
        children: groupStats.map((stats) {
          final name = nameById[stats.groupId] ?? stats.groupId;
          final hasResults = stats.assessmentsCount > 0;
          return SolidListTile(
            title: name,
            goldOutline: false,
            dense: true,
            marginBottom: 10,
            bodyBelowTitle: hasResults
                ? Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _metricChip('Overall', stats.averages.overall),
                      _metricChip('Puntualidad', stats.averages.punctuality),
                      _metricChip(
                          'Contribuciones', stats.averages.contributions),
                      _metricChip('Compromiso', stats.averages.commitment),
                      _metricChip('Actitud', stats.averages.attitude),
                    ],
                  )
                : Text(
                    'Sin evaluaciones registradas.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(.65)),
                  ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      stats.assessmentsCount.toString(),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    Text(
                      stats.assessmentsCount == 1
                          ? 'evaluación'
                          : 'evaluaciones',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(.6)),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                const Icon(Icons.chevron_right, size: 18),
              ],
            ),
            onTap: () => Get.toNamed(
              AppRoutes.peerReviewGroupSummary,
              arguments: {
                'courseId': widget.courseId,
                'groupId': stats.groupId,
                'activityIds': activityIds,
                'groupName': name,
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _activitiesSection(List<CourseActivity> activities) {
    return SectionCard(
      title: 'Actividades consideradas (${activities.length})',
      leadingIcon: Icons.list_alt,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: activities
            .map(
              (a) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.task_alt, size: 18),
                title: Text(a.title),
                subtitle: a.dueDate != null
                    ? Text('Cierre: ${_fmtDate(a.dueDate!)}')
                    : null,
              ),
            )
            .toList(),
      ),
    );
  }

  ScoreAverages? _weightedAverage(List<GroupCrossActivityStats> groups) {
    double weightSum = 0;
    double punctuality = 0;
    double contributions = 0;
    double commitment = 0;
    double attitude = 0;
    double overall = 0;

    for (final g in groups) {
      final weight = g.assessmentsCount.toDouble();
      if (weight <= 0) continue;
      weightSum += weight;
      punctuality += g.averages.punctuality * weight;
      contributions += g.averages.contributions * weight;
      commitment += g.averages.commitment * weight;
      attitude += g.averages.attitude * weight;
      overall += g.averages.overall * weight;
    }

    if (weightSum == 0) return null;
    double r(double value) =>
        double.parse((value / weightSum).toStringAsFixed(2));

    return ScoreAverages(
      punctuality: r(punctuality),
      contributions: r(contributions),
      commitment: r(commitment),
      attitude: r(attitude),
      overall: r(overall),
    );
  }

  Widget _metricChip(String label, double value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.goldAccent.withOpacity(.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: AppTheme.goldAccent.withOpacity(.95),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.toStringAsFixed(2),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.goldAccent.withOpacity(.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.goldAccent.withOpacity(.4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: AppTheme.goldAccent.withOpacity(.95),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
