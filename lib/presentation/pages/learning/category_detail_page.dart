import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import '../../../core/config/app_routes.dart';
import '../../controllers/category_controller.dart';
import '../../controllers/group_controller.dart';
import '../../controllers/membership_controller.dart';
import '../../controllers/activity_controller.dart';
import '../../controllers/course_controller.dart';
import '../../widgets/course/course_ui_components.dart';
import '../../widgets/inactive_gate.dart';
import '../../theme/app_theme.dart';
import '../../widgets/revalidation_mixin.dart';
import '../../../core/utils/refresh_manager.dart';
import '../../../core/utils/app_event_bus.dart';

class CategoryDetailPage extends StatefulWidget {
  const CategoryDetailPage({super.key});
  @override
  State<CategoryDetailPage> createState() => _CategoryDetailPageState();
}

class _CategoryDetailPageState extends State<CategoryDetailPage>
    with RevalidationMixin {
  late final String courseId;
  late final String categoryId;
  final categoryController = Get.find<CategoryController>();
  final groupController = Get.find<GroupController>();
  final membershipController = Get.find<MembershipController>();
  final activityController = Get.find<ActivityController>();
  final courseController = Get.find<CourseController>();
  late final AppEventBus _bus;
  StreamSubscription<Object>? _sub;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    courseId = args?['courseId'] ?? '';
    categoryId = args?['categoryId'] ?? '';
    _bus = Get.find<AppEventBus>();
    _sub = _bus.stream.listen((event) {
      
      if (event is EnrollmentJoinedEvent && event.courseId == courseId) {
        revalidate(force: true);
      }
      if (event is MembershipJoinedEvent && event.courseId == courseId) {
        revalidate(force: true);
      }
      if (event is ActivityChangedEvent && event.courseId == courseId) {
        revalidate(force: true);
      }
    });
    if (courseId.isNotEmpty) {
      
      categoryController.loadByCourse(courseId);
      activityController.loadForCourse(courseId);
      groupController.loadByCourse(courseId).then((groups) {
        final ids = groups
            .where((g) => g.categoryId == categoryId)
            .map((g) => g.id)
            .toList(growable: false);
        if (ids.isNotEmpty) {
          membershipController.preloadMembershipsForGroups(ids);
          membershipController.preloadMemberCountsForGroups(ids);
        }
      });
    }
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
        key: 'categories:course:$courseId',
        ttl: const Duration(seconds: 45),
        action: () => categoryController.loadByCourse(courseId),
        force: force,
      ),
      refresh.run(
        key: 'activities:course:$courseId',
        ttl: const Duration(seconds: 20),
        action: () => activityController.loadForCourse(courseId),
        force: force,
      ),
      refresh.run(
        key: 'groups:course:$courseId:category:$categoryId',
        ttl: const Duration(seconds: 45),
        action: () async {
          final groups = await groupController.loadByCourse(courseId);
          final ids = groups
              .where((g) => g.categoryId == categoryId)
              .map((g) => g.id)
              .toList(growable: false);
          if (ids.isNotEmpty) {
            await membershipController.preloadMembershipsForGroups(ids);
            await membershipController.preloadMemberCountsForGroups(ids);
          }
        },
        force: force,
      ),
    ]);
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
            child: _activitiesGated(isTeacher, isInactiveCourse),
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
                
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (isTeacher) ...[
            DualActionButtons(
              primaryLabel: 'NUEVA',
              secondaryLabel: 'VER TODAS',
              primaryIcon: Icons.add_task,
              secondaryIcon: Icons.visibility,
              primaryEnabled: !isInactiveCourse,
              onPrimary: () =>
                  Get.toNamed(AppRoutes.activityCreate, arguments: {
                'courseId': courseId,
                'categoryId': categoryId,
                'lockCourse': true,
                'lockCategory': true
              }),
              onSecondary: () => Get.toNamed(AppRoutes.categoryActivities,
                  arguments: {'courseId': courseId, 'categoryId': categoryId}),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.visibility),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
                onPressed: () => Get.toNamed(AppRoutes.categoryActivities,
                    arguments: {
                      'courseId': courseId,
                      'categoryId': categoryId
                    }),
                label: const Text('VER TODAS'),
              ),
            ),
          ],
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
        if (isTeacher) ...[
          DualActionButtons(
            primaryLabel: 'NUEVA',
            secondaryLabel: 'VER TODAS',
            primaryIcon: Icons.add_task,
            secondaryIcon: Icons.visibility,
            primaryEnabled: !isInactiveCourse,
            onPrimary: () => Get.toNamed(AppRoutes.activityCreate, arguments: {
              'courseId': courseId,
              'categoryId': categoryId,
              'lockCourse': true,
              'lockCategory': true
            }),
            onSecondary: () => Get.toNamed(AppRoutes.categoryActivities,
                arguments: {'courseId': courseId, 'categoryId': categoryId}),
          ),
        ] else ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.visibility),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
              onPressed: () => Get.toNamed(AppRoutes.categoryActivities,
                  arguments: {'courseId': courseId, 'categoryId': categoryId}),
              label: const Text('VER TODAS'),
            ),
          ),
        ],
      ],
    );
  }

  
  Widget _activitiesGated(bool isTeacher, bool isInactiveCourse) {
    if (isTeacher) {
      return _activitiesPreview(true, isInactiveCourse);
    }
    
    final groups = groupController.groupsByCourse[courseId]
            ?.where((g) => g.categoryId == categoryId)
            .toList() ??
        [];
    final groupIds = groups.map((g) => g.id).toList();
    final myJoined = membershipController.myGroupIds;
    final isMember = groupIds.any(myJoined.contains);
    if (!isMember) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppTheme.goldAccent.withOpacity(.35), width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_outline,
                    color: AppTheme.goldAccent.withOpacity(.8)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Debes unirte a un grupo de esta categoría para ver sus actividades.',
                    style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(.75)),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    return _activitiesPreview(false, isInactiveCourse);
  }

  Widget _groupsList(List groups, bool isTeacher, bool isInactiveCourse) {
    
    final myIds = membershipController.myGroupIds;
    final hasJoinedInCategory = groups.any((g) => myIds.contains(g.id));

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
                
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (isTeacher) ...[
            DualActionButtons(
              primaryLabel: 'NUEVO',
              secondaryLabel: 'VER TODOS',
              primaryIcon: Icons.group_add,
              secondaryIcon: Icons.visibility,
              primaryEnabled: !isInactiveCourse,
              onPrimary: () => Get.toNamed(AppRoutes.groupCreate, arguments: {
                'courseId': courseId,
                'categoryId': categoryId,
                'lockCourse': true,
                'lockCategory': true
              }),
              onSecondary: () => Get.toNamed(AppRoutes.categoryGroups,
                  arguments: {'courseId': courseId, 'categoryId': categoryId}),
            ),
          ] else ...[
            
            if (!hasJoinedInCategory) _fullWidthViewAllButton(),
          ],
        ],
      );
    }
    
    final showList = (!isTeacher && hasJoinedInCategory)
        ? groups.where((g) => myIds.contains(g.id)).toList()
        : groups;

    return Column(
      children: [
        ...showList.map((g) {
          final count = membershipController.groupMemberCounts[g.id] ?? 0;
          return SolidListTile(
            title: g.name,
            bodyBelowTitle: Align(
              alignment: Alignment.centerLeft,
              child: Pill(
                text: 'Miembros: $count',
                icon: Icons.people_outline,
              ),
            ),
            leadingIcon: Icons.group_work,
            onTap: () => Get.toNamed(AppRoutes.groupDetail, arguments: {
              'courseId': courseId,
              'groupId': g.id,
            }),
          );
        }),
        const SizedBox(height: 4),
        if (isTeacher) ...[
          DualActionButtons(
            primaryLabel: 'NUEVO',
            secondaryLabel: 'VER TODOS',
            primaryIcon: Icons.group_add,
            secondaryIcon: Icons.visibility,
            primaryEnabled: !isInactiveCourse,
            onPrimary: () => Get.toNamed(AppRoutes.groupCreate, arguments: {
              'courseId': courseId,
              'categoryId': categoryId,
              'lockCourse': true,
              'lockCategory': true
            }),
            onSecondary: () => Get.toNamed(AppRoutes.categoryGroups,
                arguments: {'courseId': courseId, 'categoryId': categoryId}),
          ),
        ] else ...[
          if (!hasJoinedInCategory) _fullWidthViewAllButton(),
        ],
      ],
    );
  }

  
  Widget _fullWidthViewAllButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.visibility),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.successGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
        onPressed: () => Get.toNamed(AppRoutes.categoryGroups, arguments: {
          'courseId': courseId,
          'categoryId': categoryId,
        }),
        label: const Text('VER TODOS'),
      ),
    );
  }
}
