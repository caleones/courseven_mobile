import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import '../../../core/config/app_routes.dart';
import '../../controllers/activity_controller.dart';
import '../../controllers/category_controller.dart';
import '../../controllers/course_controller.dart';
import '../../widgets/course/course_ui_components.dart';
import '../../theme/app_theme.dart';
import '../../widgets/revalidation_mixin.dart';
import '../../../core/utils/refresh_manager.dart';
import '../../../core/utils/app_event_bus.dart';

class CategoryActivitiesPage extends StatefulWidget {
  const CategoryActivitiesPage({super.key});
  @override
  State<CategoryActivitiesPage> createState() => _CategoryActivitiesPageState();
}

class _CategoryActivitiesPageState extends State<CategoryActivitiesPage>
    with RevalidationMixin {
  late final String courseId;
  late final String categoryId;
  final activityController = Get.find<ActivityController>();
  final categoryController = Get.find<CategoryController>();
  final courseController = Get.find<CourseController>();
  late final AppEventBus _bus;
  StreamSubscription<Object>? _sub;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    courseId = args?['courseId'] ?? '';
    categoryId = args?['categoryId'] ?? '';
    if (courseId.isNotEmpty) {
      activityController.loadForCourse(courseId);
      categoryController.loadByCourse(courseId);
    }
    _bus = Get.find<AppEventBus>();
    _sub = _bus.stream.listen((event) {
      if (event is MembershipJoinedEvent && event.courseId == courseId) {
        revalidate(force: true);
      }
      if (event is ActivityChangedEvent && event.courseId == courseId) {
        revalidate(force: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final acts = (activityController.activitiesByCourse[courseId] ?? const [])
          .where((a) => a.categoryId == categoryId)
          .toList();
      final category = categoryController.categoriesByCourse[courseId]
          ?.firstWhereOrNull((c) => c.id == categoryId);
      final course = courseController.coursesCache[courseId];
      final isTeacher = course?.teacherId == activityController.currentUserId;

      return CoursePageScaffold(
        header: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CourseHeader(
              title: category?.name ?? 'Categoría',
              subtitle: 'Actividades',
              showEdit: false,
            ),
            const SizedBox(height: 8),
            _countPill(label: 'Cantidad', value: acts.length.toString()),
          ],
        ),
        sections: [
          
          _list(acts, isTeacher),
        ],
      );
    });
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

  Widget _list(List acts, bool isTeacher) {
    if (activityController.isLoading.value && acts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (acts.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 26),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.goldAccent.withOpacity(.35)),
            ),
            child: Column(
              children: [
                Icon(Icons.filter_none,
                    size: 42, color: AppTheme.goldAccent.withOpacity(.65)),
                const SizedBox(height: 12),
                Text('No hay actividades',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(.75))),
              ],
            ),
          ),
          if (isTeacher) ...[
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_task),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.goldAccent,
                  foregroundColor: AppTheme.premiumBlack,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                ),
                onPressed: () =>
                    Get.toNamed(AppRoutes.activityCreate, arguments: {
                  'courseId': courseId,
                  'categoryId': categoryId,
                  'lockCourse': true,
                  'lockCategory': true,
                }),
                label: const Text('NUEVA',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ],
      );
    }
    return Column(
      children: [
        if (isTeacher) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_task),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldAccent,
                foregroundColor: AppTheme.premiumBlack,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              onPressed: () =>
                  Get.toNamed(AppRoutes.activityCreate, arguments: {
                'courseId': courseId,
                'categoryId': categoryId,
                'lockCourse': true,
                'lockCategory': true,
              }),
              label: const Text('NUEVA'),
            ),
          ),
          const SizedBox(height: 12),
        ],
        ...acts.map((a) {
          
          final dueDateStr = a.dueDate != null
              ? '${a.dueDate!.year}-${a.dueDate!.month.toString().padLeft(2, '0')}-${a.dueDate!.day.toString().padLeft(2, '0')}'
              : null;

          final duePill = dueDateStr != null
              ? Pill(text: 'Vence: $dueDateStr', icon: Icons.schedule)
              : Pill(
                  text: 'Sin fecha límite',
                  icon: Icons.schedule_outlined,
                );

          return SolidListTile(
            title: a.title,
            subtitle: null, 
            trailing: duePill,
            leadingIcon: Icons.task_outlined,
            onTap: () => Get.toNamed(AppRoutes.activityDetail,
                arguments: {'courseId': courseId, 'activityId': a.id}),
          );
        }),
        
      ],
    );
  }

  

  Widget _countPill({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.goldAccent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ',
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: AppTheme.premiumBlack)),
          Text(value,
              style: const TextStyle(
                  fontFamily: 'monospace',
                  color: AppTheme.premiumBlack,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
