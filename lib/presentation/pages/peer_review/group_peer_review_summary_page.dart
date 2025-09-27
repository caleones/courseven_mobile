import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/activity_controller.dart';
import '../../controllers/course_controller.dart';
import '../../controllers/enrollment_controller.dart';
import '../../controllers/group_controller.dart';
import '../../controllers/peer_review_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/course/course_ui_components.dart';
import '../../../domain/models/course_activity.dart';
import '../../../domain/models/membership.dart';
import '../../../domain/models/peer_review_summaries.dart';
import '../../../domain/repositories/membership_repository.dart';

class GroupCoursePeerResultsPage extends StatefulWidget {
  final String courseId;
  final String groupId;
  final List<String> activityIds;
  final String? groupName;
  const GroupCoursePeerResultsPage({
    super.key,
    required this.courseId,
    required this.groupId,
    required this.activityIds,
    this.groupName,
  });

  @override
  State<GroupCoursePeerResultsPage> createState() =>
      _GroupCoursePeerResultsPageState();
}

class _GroupCoursePeerResultsPageState
    extends State<GroupCoursePeerResultsPage> {
  final activityController = Get.find<ActivityController>();
  final courseController = Get.find<CourseController>();
  final enrollmentController = Get.find<EnrollmentController>();
  final groupController = Get.find<GroupController>();
  final peerReviewController = Get.find<PeerReviewController>();
  late final MembershipRepository membershipRepository;

  bool _membersLoading = false;
  String? _membersError;
  List<Membership> _memberships = const [];
  bool _requestedSummary = false;

  @override
  void initState() {
    super.initState();
    membershipRepository = Get.find<MembershipRepository>();
    if (widget.courseId.isNotEmpty) {
      courseController.getCourseById(widget.courseId);
      enrollmentController.loadEnrollmentsForCourse(widget.courseId);
      groupController.loadByCourse(widget.courseId);
      if (widget.activityIds.isEmpty) {
        activityController.loadForCourse(widget.courseId);
      }
    }
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    if (widget.groupId.isEmpty) return;
    setState(() {
      _membersLoading = true;
      _membersError = null;
    });
    try {
      final list =
          await membershipRepository.getMembershipsByGroupId(widget.groupId);
      for (final m in list) {
        await enrollmentController.ensureUserLoaded(m.userId);
      }
      if (!mounted) return;
      setState(() {
        _memberships = list;
        _membersLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _membersError = e.toString();
        _membersLoading = false;
      });
    }
  }

  Future<void> _refresh(List<String> activityIds) async {
    final ids = activityIds.isNotEmpty ? activityIds : _currentActivityIds();
    if (ids.isEmpty) return;
    await peerReviewController.loadCourseSummary(
      courseId: widget.courseId,
      activityIds: ids,
      force: true,
    );
    await _loadMembers();
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

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final activities =
          activityController.activitiesByCourse[widget.courseId] ??
              const <CourseActivity>[];
      final activityIds = widget.activityIds.isNotEmpty
          ? widget.activityIds
          : _currentActivityIds();
      final course = courseController.coursesCache[widget.courseId];
      final groups =
          groupController.groupsByCourse[widget.courseId] ?? const [];
      final groupName = widget.groupName?.isNotEmpty == true
          ? widget.groupName!
          : groups.firstWhereOrNull((g) => g.id == widget.groupId)?.name ??
              'Grupo';
      if (!_requestedSummary && activityIds.isNotEmpty) {
        _requestedSummary = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          peerReviewController.loadCourseSummary(
            courseId: widget.courseId,
            activityIds: activityIds,
            force: true,
          );
        });
      }
      final summary = peerReviewController.courseSummary(widget.courseId);
      final statsByStudent = <String, StudentCrossActivityStats>{};
      if (summary != null) {
        for (final s in summary.students) {
          statsByStudent[s.studentId] = s;
        }
      }
      final groupStats =
          summary?.groups.firstWhereOrNull((g) => g.groupId == widget.groupId);

      final sections = _buildSections(
        activityIds: activityIds,
        activities: activities,
        groupStats: groupStats,
        statsByStudent: statsByStudent,
      );

      return CoursePageScaffold(
        header: CourseHeader(
          title: groupName,
          subtitle: course != null
              ? 'Promedios globales · ${course.name}'
              : 'Promedios de Peer Review',
          showEdit: false,
        ),
        sections: sections,
        onRefresh: () => _refresh(activityIds),
      );
    });
  }

  List<Widget> _buildSections({
    required List<String> activityIds,
    required List<CourseActivity> activities,
    required GroupCrossActivityStats? groupStats,
    required Map<String, StudentCrossActivityStats> statsByStudent,
  }) {
    final sections = <Widget>[];
    if (activityIds.isEmpty) {
      sections.add(
        SectionCard(
          title: 'Sin actividades',
          leadingIcon: Icons.info_outline,
          child: const Text(
              'No hay actividades públicas de peer review consideradas para el curso.'),
        ),
      );
      sections.add(_membersSection(statsByStudent));
      return sections;
    }

    if (peerReviewController.isLoading.value && groupStats == null) {
      sections.add(
        const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: CircularProgressIndicator(),
          ),
        ),
      );
      return sections;
    }

    if (groupStats == null || groupStats.assessmentsCount == 0) {
      sections.add(
        SectionCard(
          title: 'Sin evaluaciones registradas',
          leadingIcon: Icons.bar_chart,
          child: const Text(
              'Este grupo aún no ha recibido evaluaciones en las actividades públicas.'),
        ),
      );
    } else {
      sections.add(_groupAveragesCard(groupStats));
      sections.add(_groupMetaCard(
        groupStats: groupStats,
        activityCount: activityIds.length,
      ));
    }

    sections.add(_membersSection(statsByStudent));

    final considered = activities
        .where((a) => activityIds.contains(a.id))
        .toList(growable: false);
    if (considered.isNotEmpty) {
      sections.add(_activitiesSection(considered));
    }
    return sections;
  }

  Widget _groupAveragesCard(GroupCrossActivityStats stats) {
    final avg = stats.averages;
    return SectionCard(
      title:
          'Promedios del grupo (${stats.assessmentsCount} ${stats.assessmentsCount == 1 ? 'evaluación' : 'evaluaciones'})',
      leadingIcon: Icons.insights_outlined,
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          _metricChip('Overall', avg.overall),
          _metricChip('Puntualidad', avg.punctuality),
          _metricChip('Contribuciones', avg.contributions),
          _metricChip('Compromiso', avg.commitment),
          _metricChip('Actitud', avg.attitude),
        ],
      ),
    );
  }

  Widget _groupMetaCard({
    required GroupCrossActivityStats groupStats,
    required int activityCount,
  }) {
    return SectionCard(
      title: 'Resumen',
      leadingIcon: Icons.article_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _kv('Evaluaciones registradas',
              groupStats.assessmentsCount.toString()),
          _kv('Actividades consideradas', activityCount.toString()),
          _kv('Integrantes detectados', _memberships.length.toString()),
        ],
      ),
    );
  }

  Widget _membersSection(
      Map<String, StudentCrossActivityStats> statsByStudent) {
    if (_membersLoading && _memberships.isEmpty) {
      return SectionCard(
        title: 'Integrantes',
        leadingIcon: Icons.people_alt,
        child: const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }
    if (_membersError != null && _memberships.isEmpty) {
      return SectionCard(
        title: 'Integrantes',
        leadingIcon: Icons.people_alt,
        child: Text(
          'No fue posible cargar los integrantes: $_membersError',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Theme.of(context).colorScheme.error),
        ),
      );
    }
    if (_memberships.isEmpty) {
      return SectionCard(
        title: 'Integrantes',
        leadingIcon: Icons.people_alt,
        child: const Text('El grupo aún no tiene integrantes registrados.'),
      );
    }
    final sorted = List<Membership>.from(_memberships)
      ..sort((a, b) {
        final nameA = enrollmentController.userName(a.userId).toLowerCase();
        final nameB = enrollmentController.userName(b.userId).toLowerCase();
        return nameA.compareTo(nameB);
      });
    return SectionCard(
      title: 'Integrantes',
      leadingIcon: Icons.people_alt,
      child: Column(
        children: sorted.map((membership) {
          final stats = statsByStudent[membership.userId];
          final name = enrollmentController.userName(membership.userId);
          return SolidListTile(
            title: name,
            goldOutline: false,
            dense: true,
            bodyBelowTitle: stats != null
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
                    'Sin evaluaciones registradas en las actividades públicas.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(.65)),
                  ),
            trailing: stats != null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        stats.assessmentsReceived.toString(),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      Text(
                        stats.assessmentsReceived == 1
                            ? 'evaluación'
                            : 'evaluaciones',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(.6)),
                      ),
                    ],
                  )
                : null,
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

  Widget _kv(String key, String value) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 170,
            child: Text(
              key,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: onSurface.withOpacity(.75)),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
