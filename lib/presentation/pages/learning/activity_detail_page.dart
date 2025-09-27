import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import '../../../core/config/app_routes.dart';
import '../../controllers/activity_controller.dart';
import '../../controllers/category_controller.dart';
import '../../controllers/course_controller.dart';
import '../../widgets/course/course_ui_components.dart';
import '../../theme/app_theme.dart';
import '../../controllers/peer_review_controller.dart';
import '../../../domain/models/course_activity.dart';
import '../../../domain/repositories/assessment_repository.dart';
import '../../../domain/repositories/membership_repository.dart';
import '../../../domain/repositories/group_repository.dart';
import '../../widgets/revalidation_mixin.dart';
import '../../../core/utils/refresh_manager.dart';
import '../../../core/utils/app_event_bus.dart';

class ActivityDetailPage extends StatefulWidget {
  const ActivityDetailPage({super.key});
  @override
  State<ActivityDetailPage> createState() => _ActivityDetailPageState();
}

class _ActivityDetailPageState extends State<ActivityDetailPage>
    with RevalidationMixin {
  late final String courseId;
  late final String activityId;
  final activityController = Get.find<ActivityController>();
  final categoryController = Get.find<CategoryController>();
  final courseController = Get.find<CourseController>();
  PeerReviewController? _peerReviewController;
  late final AppEventBus _bus;
  StreamSubscription<Object>? _sub;

  final Set<String> _prLoaded = <String>{};

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    courseId = args?['courseId'] ?? '';
    activityId = args?['activityId'] ?? '';
    if (courseId.isNotEmpty) {
      activityController.loadForCourse(courseId);
      categoryController.loadByCourse(courseId);
    }
    _bus = Get.find<AppEventBus>();
    _sub = _bus.stream.listen((event) {
      if (event is ActivityChangedEvent && event.courseId == courseId) {
        revalidate(force: true);
      }
    });

    try {
      _peerReviewController = Get.find<PeerReviewController>();
    } catch (_) {
      try {
        final assessmentRepo = Get.find<AssessmentRepository>();
        final membershipRepo = Get.find<MembershipRepository>();
        final groupRepo = Get.find<GroupRepository>();
        _peerReviewController = Get.put(
            PeerReviewController(assessmentRepo, membershipRepo, groupRepo));
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final activities = activityController.activitiesByCourse[courseId] ?? [];
      final activity = activities.firstWhereOrNull((a) => a.id == activityId);
      if (activity == null) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      final isTeacher = courseController.coursesCache[courseId]?.teacherId ==
          activityController.currentUserId;
      final category = categoryController.categoriesByCourse[courseId]
          ?.firstWhereOrNull((c) => c.id == activity.categoryId);

      final dueText = activity.dueDate != null
          ? _fmtDate(activity.dueDate!)
          : 'Sin fecha límite';
      final description = activity.description?.trim().isNotEmpty == true
          ? activity.description!.trim()
          : 'Sin descripción';

      _ensurePeerReviewLoaded(activity);

      final sections = <Widget>[
        _metaRow(category?.name, dueText, activity.isActive),
        _descriptionCard(description),
      ];

      if (isTeacher) {
        sections.add(_teacherPeerReviewCard(activity));
        sections.add(const SizedBox(height: 12));
        sections.add(_teacherRequestButton(activity));
        if (activity.reviewing) {
          sections.add(const SizedBox(height: 12));
          sections.add(_teacherResultsButton(activity));
        }
      } else {
        sections.add(_studentPeerReviewCard(activity));
        if (activity.reviewing) {
          sections.add(const SizedBox(height: 12));
          sections.add(_studentResultsButton(activity));
        }
      }

      return CoursePageScaffold(
        header: CourseHeader(
          title: activity.title,
          subtitle: 'Actividad',
          showEdit: isTeacher,
          inactive: !activity.isActive,
          onEdit: isTeacher
              ? () => Get.toNamed(AppRoutes.activityEdit,
                  arguments: {'courseId': courseId, 'activityId': activity.id})
              : null,
        ),
        sections: sections,
      );
    });
  }

  void _ensurePeerReviewLoaded(CourseActivity activity) {
    if (_peerReviewController == null) return;
    if (!activity.reviewing) return;
    if (_prLoaded.contains(activity.id)) return;
    _prLoaded.add(activity.id);

    _peerReviewController!.loadForActivity(activity);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Duration? get pollingInterval => const Duration(seconds: 60);

  @override
  Future<void> revalidate({bool force = false}) async {
    if (courseId.isEmpty) return;
    final refresh = Get.find<RefreshManager>();
    await Future.wait([
      refresh.run(
        key: 'activities:course:$courseId',
        ttl: const Duration(seconds: 20),
        action: () => activityController.loadForCourse(courseId),
        force: force,
      ),
      refresh.run(
        key: 'categories:course:$courseId',
        ttl: const Duration(seconds: 45),
        action: () => categoryController.loadByCourse(courseId),
        force: force,
      ),
    ]);
  }

  Widget _metaRow(String? categoryName, String dueText, bool isActive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _pill(
          icon: Icons.folder_special,
          label: 'Categoría',
          value: categoryName ?? 'Desconocida',
        ),
        const SizedBox(height: 10),
        _pill(
          icon: Icons.timer_outlined,
          label: 'Vence',
          value: dueText,
          highlight: !dueText.contains('Sin'),
        ),
        const SizedBox(height: 10),
        _solidPill(
          icon: isActive ? Icons.play_circle_fill : Icons.pause_circle_filled,
          label: 'Estado',
          value: isActive ? 'Activa' : 'Inactiva',
          color: isActive ? AppTheme.successGreen : Colors.orange,
        ),
      ],
    );
  }

  Widget _pill({
    required IconData icon,
    required String label,
    required String value,
    bool highlight = false,
    Color? color,
  }) {
    final c = color ?? AppTheme.goldAccent;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.withOpacity(.55), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: c),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(),
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: c.withOpacity(.9))),
              const SizedBox(height: 2),
              Text(value,
                  style: TextStyle(
                      fontFamily: highlight ? 'monospace' : null,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                      color: onSurface)),
            ],
          )
        ],
      ),
    );
  }

  Widget _solidPill({
    required IconData icon,
    required String label,
    required String value,
    bool highlight = false,
    Color? color,
  }) {
    final c = color ?? AppTheme.goldAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppTheme.premiumBlack),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: AppTheme.premiumBlack)),
              const SizedBox(height: 2),
              Text(value,
                  style: TextStyle(
                      fontFamily: highlight ? 'monospace' : null,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                      color: AppTheme.premiumBlack)),
            ],
          )
        ],
      ),
    );
  }

  Widget _descriptionCard(String description) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.goldAccent.withOpacity(.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Descripción',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(description),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Widget _teacherPeerReviewCard(CourseActivity activity) {
    final canActivate = !activity.reviewing;
    return Card(
      margin: const EdgeInsets.only(top: 20),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Peer Review',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 8),
            Text(activity.reviewing
                ? 'Estado: Activo (${activity.privateReview ? 'Resultados privados' : 'Resultados públicos'})'
                : 'Aún no activado.'),
            if (!canActivate)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                    'Puedes solicitar revisión cuando quieras ajustar la visibilidad.'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _teacherRequestButton(CourseActivity activity) {
    final canActivate = !activity.reviewing;
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: canActivate
            ? () async {
                final isPrivate = await _pickVisibility();
                if (isPrivate == null) return;
                await activityController.requestPeerReview(
                    activityId: activity.id, isPrivate: isPrivate);
              }
            : null,
        child: const Text('SOLICITAR REVISIÓN'),
      ),
    );
  }

  Future<bool?> _pickVisibility() async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Visibilidad resultados'),
        content: const Text(
            '¿Cómo desea mostrar los resultados a estudiantes cuando completen sus evaluaciones?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Privados')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Públicos')),
        ],
      ),
    );
  }

  Widget _studentPeerReviewCard(CourseActivity activity) {
    if (!activity.reviewing) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.only(top: 20),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Text('Peer Review',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () {
                Get.toNamed(AppRoutes.peerReviewList, arguments: {
                  'courseId': courseId,
                  'activityId': activity.id,
                });
              },
              child: const Text('CALIFICAR'),
            )
          ],
        ),
      ),
    );
  }

  Widget _teacherResultsButton(CourseActivity activity) {
    if (!activity.reviewing) return const SizedBox.shrink();
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () {
          Get.toNamed(AppRoutes.activityPeerReviewResults, arguments: {
            'courseId': courseId,
            'activityId': activity.id,
          });
        },
        icon: const Icon(Icons.bar_chart),
        label: const Text('RESULTADOS'),
      ),
    );
  }

  Widget _studentResultsButton(CourseActivity activity) {
    if (!activity.reviewing || activity.privateReview) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () {
          Get.toNamed(AppRoutes.studentPeerReviewOwnResults, arguments: {
            'courseId': courseId,
            'activityId': activity.id,
          });
        },
        icon: const Icon(Icons.visibility),
        label: const Text('MIS RESULTADOS'),
      ),
    );
  }
}
