import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/config/app_routes.dart';
import '../../controllers/activity_controller.dart';
import '../../controllers/category_controller.dart';
import '../../controllers/course_controller.dart';
import '../../widgets/course/course_ui_components.dart';
import '../../theme/app_theme.dart';
import '../../controllers/peer_review_controller.dart';
import '../../../domain/models/course_activity.dart';

class ActivityDetailPage extends StatefulWidget {
  const ActivityDetailPage({super.key});
  @override
  State<ActivityDetailPage> createState() => _ActivityDetailPageState();
}

class _ActivityDetailPageState extends State<ActivityDetailPage> {
  late final String courseId;
  late final String activityId;
  final activityController = Get.find<ActivityController>();
  final categoryController = Get.find<CategoryController>();
  final courseController = Get.find<CourseController>();
  PeerReviewController? _peerReviewController;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    courseId = args?['courseId'] ?? '';
    activityId = args?['activityId'] ?? '';
    if (courseId.isNotEmpty) {
      activityController.loadForCourse(courseId); // ensure cache
      categoryController.loadByCourse(courseId);
    }
    // Lazy find peer review controller if está registrado en bindings
    try {
      _peerReviewController = Get.find<PeerReviewController>();
    } catch (_) {
      // ignorar si no está disponible
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
        sections: [
          _metaRow(category?.name, dueText, activity.isActive),
          _descriptionCard(description),
          if (isTeacher) _teacherPeerReviewCard(activity),
          if (!isTeacher) _studentPeerReviewCard(activity),
          if (isTeacher && activity.reviewing) _teacherSummarySection(activity),
        ],
      );
    });
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
    final canActivate = !activity.reviewing &&
        activity.dueDate != null &&
        DateTime.now().isAfter(activity.dueDate!);
    final changingToPublic =
        activity.reviewing && activity.peerVisibility == 'private';
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
                ? 'Estado: Activo (${activity.peerVisibility == 'public' ? 'Resultados públicos' : 'Resultados privados'})'
                : 'Aún no activado. Se puede activar tras el due date.'),
            const SizedBox(height: 12),
            Row(children: [
              ElevatedButton(
                onPressed: canActivate
                    ? () async {
                        final visibility = await _pickVisibility();
                        if (visibility == null) return;
                        await activityController.requestPeerReview(
                            activityId: activity.id,
                            peerVisibility: visibility);
                      }
                    : null,
                child: const Text('Activar Peer Review'),
              ),
              const SizedBox(width: 12),
              if (changingToPublic)
                OutlinedButton(
                  onPressed: () async {
                    await activityController.requestPeerReview(
                        activityId: activity.id, peerVisibility: 'public');
                  },
                  child: const Text('Hacer Públicos'),
                ),
            ])
          ],
        ),
      ),
    );
  }

  Future<String?> _pickVisibility() async {
    return await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Visibilidad resultados'),
        content: const Text(
            '¿Cómo desea mostrar los resultados a estudiantes cuando completen sus evaluaciones?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, 'private'),
              child: const Text('Privados')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, 'public'),
              child: const Text('Públicos')),
        ],
      ),
    );
  }

  Widget _studentPeerReviewCard(CourseActivity activity) {
    if (_peerReviewController == null) return const SizedBox.shrink();
    final pr = _peerReviewController!;
    final progress = pr.progressFor(activity.id);
    final canReview = pr.canStudentReview(activity,
        isMemberOfGroup: true); // TODO: integrar verificación real de membresía
    if (!activity.reviewing) return const SizedBox.shrink();
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
            if (!canReview)
              const Text(
                  'No eres elegible para realizar peer review en esta actividad.'),
            if (canReview)
              Row(
                children: [
                  Expanded(
                    child: Text(
                        'Progreso: ${(progress['done'] ?? 0)} / ${(progress['total'] ?? 0)}'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Get.toNamed(AppRoutes.peerReviewList, arguments: {
                        'courseId': courseId,
                        'activityId': activity.id,
                      });
                    },
                    child: const Text('Revisar'),
                  )
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _teacherSummarySection(CourseActivity activity) {
    if (_peerReviewController == null) return const SizedBox.shrink();
    final pr = _peerReviewController!;
    final summary = pr.activitySummary(activity.id);
    return Obx(() {
      final loading = pr.isLoading.value && summary == null;
      return Card(
        margin: const EdgeInsets.only(top: 20),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : summary == null
                  ? const Text('Aún no hay evaluaciones.')
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Resumen Peer Review',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 16)),
                        const SizedBox(height: 12),
                        Text(
                            'Promedio Actividad (Overall): ${summary.activityAverages.overall.toStringAsFixed(2)}'),
                        const SizedBox(height: 8),
                        ...summary.groups.map((g) => ExpansionTile(
                              title: Text(
                                  'Grupo ${g.groupId} - Avg ${g.averages.overall.toStringAsFixed(2)}'),
                              children: g.students
                                  .map((s) => ListTile(
                                        title:
                                            Text('Estudiante ${s.studentId}'),
                                        subtitle: Text(
                                            'Overall ${s.averages.overall.toStringAsFixed(2)} | P:${s.averages.punctuality.toStringAsFixed(2)} C:${s.averages.contributions.toStringAsFixed(2)} Cm:${s.averages.commitment.toStringAsFixed(2)} A:${s.averages.attitude.toStringAsFixed(2)}'),
                                      ))
                                  .toList(),
                            ))
                      ],
                    ),
        ),
      );
    });
  }
}
