import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/config/app_routes.dart';
import '../../controllers/category_controller.dart';
import '../../controllers/group_controller.dart';
import '../../controllers/membership_controller.dart';
import '../../controllers/activity_controller.dart';
import '../../controllers/course_controller.dart';
import '../../widgets/course/course_ui_components.dart';
import '../../widgets/inactive_gate.dart';
import '../../theme/app_theme.dart';

class CategoryDetailPage extends StatefulWidget {
  const CategoryDetailPage({super.key});
  @override
  State<CategoryDetailPage> createState() => _CategoryDetailPageState();
}

class _CategoryDetailPageState extends State<CategoryDetailPage> {
  late final String courseId;
  late final String categoryId;
  final categoryController = Get.find<CategoryController>();
  final groupController = Get.find<GroupController>();
  final membershipController = Get.find<MembershipController>();
  final activityController = Get.find<ActivityController>();
  final courseController = Get.find<CourseController>();

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    courseId = args?['courseId'] ?? '';
    categoryId = args?['categoryId'] ?? '';
    if (courseId.isNotEmpty) {
      categoryController.loadByCourse(courseId).then((_) {
        activityController.loadForCourse(courseId); // ensure activities cache
        groupController.loadByCourse(courseId).then((groups) {
          final catGroups =
              groups.where((g) => g.categoryId == categoryId).toList();
          final ids = catGroups.map((g) => g.id).toList();
          membershipController.preloadMemberCountsForGroups(ids);
          if (mounted) setState(() {});
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final categories = categoryController.categoriesByCourse[courseId] ?? [];
      final category = categories.firstWhereOrNull((c) => c.id == categoryId);
      if (category == null) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      final isTeacher = courseController.coursesCache[courseId]?.teacherId ==
          courseController.currentTeacherId;
      final groups = groupController.groupsByCourse[courseId]
              ?.where((g) => g.categoryId == categoryId)
              .toList() ??
          [];
      final isInactiveCourse =
          !(courseController.coursesCache[courseId]?.isActive ?? true);

      return CoursePageScaffold(
        header: CourseHeader(
          title: category.name,
          subtitle: 'Categoría',
          showEdit: isTeacher,
          onEdit: () {
            Get.toNamed(AppRoutes.categoryEdit, arguments: {
              'courseId': courseId,
              'categoryId': categoryId,
            });
          },
        ),
        sections: [
          _descriptionCard(category.description ?? 'Sin descripción'),
          SectionCard(
            title: 'Grupos',
            count: groups.length,
            leadingIcon: Icons.groups,
            child: InactiveGate(
              inactive: isInactiveCourse,
              child: _groupsList(groups, isTeacher, isInactiveCourse),
            ),
          ),
          SectionCard(
            title: 'Actividades',
            count: _activityCountForCategory(),
            leadingIcon: Icons.task_outlined,
            child: _activitiesPreview(isTeacher, isInactiveCourse),
          ),
        ],
      );
    });
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

  int _activityCountForCategory() {
    final acts = activityController.activitiesByCourse[courseId] ?? const [];
    return acts.where((a) => a.categoryId == categoryId).length;
  }

  Widget _activitiesPreview(bool isTeacher, bool isInactiveCourse) {
    final acts = (activityController.activitiesByCourse[courseId] ?? const [])
        .where((a) => a.categoryId == categoryId)
        .toList();
    final preview = acts.take(3).toList();
    if (activityController.isLoading.value && acts.isEmpty) {
      return const Center(
          child: Padding(
              padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
    }
    if (preview.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 26),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppTheme.goldAccent.withOpacity(.35), width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
            primaryIcon: Icons.add_task,
            secondaryIcon: Icons.visibility,
            primaryEnabled: isTeacher && !isInactiveCourse,
            onPrimary: () => Get.toNamed(AppRoutes.activityCreate, arguments: {
              'courseId': courseId,
              'categoryId': categoryId,
              'lockCourse': true,
              'lockCategory': true
            }),
            onSecondary: () => Get.toNamed(AppRoutes.categoryActivities,
                arguments: {'courseId': courseId, 'categoryId': categoryId}),
          ),
        ],
      );
    }
    return Column(
      children: [
        ...preview.map((a) => SolidListTile(
              title: a.title,
              subtitle: a.dueDate != null
                  ? 'Vence: ${a.dueDate!.year}-${a.dueDate!.month.toString().padLeft(2, '0')}-${a.dueDate!.day.toString().padLeft(2, '0')}'
                  : 'Sin fecha límite',
              leadingIcon: Icons.task_outlined,
              onTap: () => Get.toNamed(AppRoutes.activityDetail,
                  arguments: {'courseId': courseId, 'activityId': a.id}),
            )),
        const SizedBox(height: 4),
        DualActionButtons(
          primaryLabel: 'CREAR ACTIVIDAD',
          secondaryLabel: 'VER TODAS',
          primaryIcon: Icons.add_task,
          secondaryIcon: Icons.visibility,
          primaryEnabled: isTeacher && !isInactiveCourse,
          onPrimary: () => Get.toNamed(AppRoutes.activityCreate, arguments: {
            'courseId': courseId,
            'categoryId': categoryId,
            'lockCourse': true,
            'lockCategory': true
          }),
          onSecondary: () => Get.toNamed(AppRoutes.categoryActivities,
              arguments: {'courseId': courseId, 'categoryId': categoryId}),
        ),
      ],
    );
  }

  Widget _groupsList(List groups, bool isTeacher, bool isInactiveCourse) {
    if (groups.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 26),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppTheme.goldAccent.withOpacity(.35), width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.blur_circular,
                    size: 42, color: AppTheme.goldAccent.withOpacity(.65)),
                const SizedBox(height: 12),
                Text('No hay grupos aún',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(.75))),
                const SizedBox(height: 6),
                Text('Crea el primero para organizar equipos',
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
            primaryLabel: 'CREAR GRUPO',
            secondaryLabel: 'VER TODOS',
            primaryIcon: Icons.group_add,
            secondaryIcon: Icons.visibility,
            primaryEnabled: isTeacher && !isInactiveCourse,
            onPrimary: () => Get.toNamed(AppRoutes.groupCreate, arguments: {
              'courseId': courseId,
              'categoryId': categoryId,
              'lockCourse': true,
              'lockCategory': true
            }),
            onSecondary: () => Get.toNamed(AppRoutes.categoryGroups,
                arguments: {'courseId': courseId, 'categoryId': categoryId}),
          ),
        ],
      );
    }
    return Column(
      children: [
        ...groups.map((g) {
          final count = membershipController.groupMemberCounts[g.id] ?? 0;
          return SolidListTile(
            title: g.name,
            subtitle: null, // Remove subtitle since we're using pills
            trailing: _simplePill('Miembros: $count', icon: Icons.people),
            leadingIcon: Icons.group_work,
          );
        }),
        const SizedBox(height: 4),
        DualActionButtons(
          primaryLabel: 'CREAR GRUPO',
          secondaryLabel: 'VER TODOS',
          primaryIcon: Icons.group_add,
          secondaryIcon: Icons.visibility,
          primaryEnabled: isTeacher && !isInactiveCourse,
          onPrimary: () => Get.toNamed(AppRoutes.groupCreate, arguments: {
            'courseId': courseId,
            'categoryId': categoryId,
            'lockCourse': true,
            'lockCategory': true
          }),
          onSecondary: () => Get.toNamed(AppRoutes.categoryGroups,
              arguments: {'courseId': courseId, 'categoryId': categoryId}),
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
