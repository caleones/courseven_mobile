import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/config/app_routes.dart';
import '../../controllers/activity_controller.dart';
import '../../controllers/category_controller.dart';
import '../../controllers/course_controller.dart';
import '../../widgets/course/course_ui_components.dart';
import '../../theme/app_theme.dart';

class CategoryActivitiesPage extends StatefulWidget {
  const CategoryActivitiesPage({super.key});
  @override
  State<CategoryActivitiesPage> createState() => _CategoryActivitiesPageState();
}

class _CategoryActivitiesPageState extends State<CategoryActivitiesPage> {
  late final String courseId;
  late final String categoryId;
  final activityController = Get.find<ActivityController>();
  final categoryController = Get.find<CategoryController>();
  final courseController = Get.find<CourseController>();

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
        header: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CourseHeader(
                title: category?.name ?? 'Categoría',
                subtitle: 'Actividades',
                showEdit: false,
              ),
            ),
            const SizedBox(width: 12),
            // Count pill at top-right
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.goldAccent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${acts.length}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.premiumBlack,
                ),
              ),
            ),
          ],
        ),
        sections: [
          // Activities content without SectionCard wrapper
          _list(acts, isTeacher),
        ],
      );
    });
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
                const SizedBox(height: 6),
                Text('Crea la primera para esta categoría',
                    style: TextStyle(
                        fontSize: 12.5,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(.55))),
              ],
            ),
          ),
          const SizedBox(height: 14),
          DualActionButtons(
            primaryLabel: 'CREAR ACTIVIDAD',
            secondaryLabel: 'VER TODAS',
            secondaryEnabled: false,
            primaryIcon: Icons.add_task,
            onPrimary: () => Get.toNamed(AppRoutes.activityCreate, arguments: {
              'courseId': courseId,
              'categoryId': categoryId,
              'lockCourse': true,
              'lockCategory': true,
            }),
          ),
        ],
      );
    }
    return Column(
      children: [
        ...acts.map((a) {
          // Create pill for due date only (no category pill since we're viewing category-specific activities)
          final dueDateStr = a.dueDate != null
              ? '${a.dueDate!.year}-${a.dueDate!.month.toString().padLeft(2, '0')}-${a.dueDate!.day.toString().padLeft(2, '0')}'
              : null;

          final duePill = dueDateStr != null
              ? _simplePill('Vence: $dueDateStr', icon: Icons.schedule)
              : _simplePill('Sin fecha límite', icon: Icons.schedule_outlined);

          return SolidListTile(
            title: a.title,
            subtitle: null, // Remove subtitle since we're using pills
            trailing: duePill,
            leadingIcon: Icons.task_outlined,
            onTap: () => Get.toNamed(AppRoutes.activityDetail,
                arguments: {'courseId': courseId, 'activityId': a.id}),
          );
        }),
        const SizedBox(height: 4),
        DualActionButtons(
          primaryLabel: 'CREAR ACTIVIDAD',
          secondaryLabel: 'VER TODAS',
          secondaryEnabled: false,
          primaryIcon: Icons.add_task,
          onPrimary: () => Get.toNamed(AppRoutes.activityCreate, arguments: {
            'courseId': courseId,
            'categoryId': categoryId,
            'lockCourse': true,
            'lockCategory': true,
          }),
        ),
      ],
    );
  }

  Widget _simplePill(String text, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.goldAccent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: AppTheme.premiumBlack),
            const SizedBox(width: 4),
          ],
          Text(text,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.premiumBlack)),
        ],
      ),
    );
  }
}
