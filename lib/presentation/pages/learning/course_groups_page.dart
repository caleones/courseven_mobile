import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import '../../controllers/group_controller.dart';
import '../../controllers/activity_controller.dart';
import '../../controllers/category_controller.dart';
import '../../controllers/membership_controller.dart';
import '../../../core/config/app_routes.dart';
import '../../controllers/course_controller.dart';
import '../../widgets/course/course_ui_components.dart';
import '../../theme/app_theme.dart';
import '../../widgets/revalidation_mixin.dart';
import '../../../core/utils/refresh_manager.dart';
import '../../../core/utils/app_event_bus.dart';

class CourseGroupsPage extends StatefulWidget {
  const CourseGroupsPage({super.key});

  @override
  State<CourseGroupsPage> createState() => _CourseGroupsPageState();
}

class _CourseGroupsPageState extends State<CourseGroupsPage>
    with RevalidationMixin {
  final groupController = Get.find<GroupController>();
  final activityController = Get.find<ActivityController>();
  final courseController = Get.find<CourseController>();
  final categoryController = Get.find<CategoryController>();
  final membershipController = Get.find<MembershipController>();
  late final String courseId;
  bool _requestedCourseLoad = false;
  late final AppEventBus _bus;
  StreamSubscription<Object>? _sub;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    courseId = args?['courseId'] ?? '';
    if (courseId.isNotEmpty) {
      groupController.loadByCourse(courseId).then((groups) async {
        
        final ids = groups.map((g) => g.id).toList(growable: false);
        if (ids.isNotEmpty) {
          await membershipController.preloadMembershipsForGroups(ids);
          await membershipController.preloadMemberCountsForGroups(ids);
        }
        if (mounted) setState(() {});
      });
      categoryController.loadByCourse(courseId);
    }
    _bus = Get.find<AppEventBus>();
    _sub = _bus.stream.listen((event) {
      if (event is MembershipJoinedEvent && event.courseId == courseId) {
        revalidate(force: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_requestedCourseLoad &&
        courseId.isNotEmpty &&
        courseController.coursesCache[courseId] == null) {
      _requestedCourseLoad = true;
      courseController.getCourseById(courseId);
    }
    return Obx(() {
      final course = courseController.coursesCache[courseId];
      final myUserId = activityController.currentUserId ?? '';
      final isTeacher = course?.teacherId == myUserId;
      final isInactive = course != null && !course.isActive;
      final displayTitle = course?.name ?? 'Curso';

      var list = groupController.groupsByCourse[courseId] ?? const [];
      
      final myIds = membershipController.myGroupIds;
      if (!isTeacher && myUserId.isNotEmpty && list.isNotEmpty) {
        
        final joinedByCategory = <String, String>{};
        for (final g in list) {
          if (myIds.contains(g.id)) joinedByCategory[g.categoryId] = g.id;
        }
        if (joinedByCategory.isNotEmpty) {
          list = list.where((g) {
            final joinedId = joinedByCategory[g.categoryId];
            if (joinedId == null) return true; 
            return g.id == joinedId; 
          }).toList();
        }
      }
      final content = groupController.isLoading.value && list.isEmpty
          ? const Center(
              child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator()))
          : (list.isEmpty
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 26),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppTheme.goldAccent.withOpacity(.35),
                            width: 1),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.blur_circular,
                              size: 42,
                              color: AppTheme.goldAccent.withOpacity(.65)),
                          const SizedBox(height: 12),
                          Text('No hay grupos aún',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(.75),
                              )),
                        ],
                      ),
                    ),
                    
                  ],
                )
              : Column(
                  children: [
                    ...list.map((g) {
                      final cat = categoryController
                          .categoriesByCourse[courseId]
                          ?.firstWhereOrNull((c) => c.id == g.categoryId);
                      final mode =
                          (cat?.groupingMethod.toLowerCase() ?? 'manual') ==
                                  'random'
                              ? 'aleatoria'
                              : 'manual';
                      final max = cat?.maxMembersPerGroup;
                      final count =
                          membershipController.groupMemberCounts[g.id] ?? 0;
                      final categoryPill = cat != null
                          ? Pill(
                              text: 'Categoría: ${cat.name}',
                              icon: Icons.folder_open)
                          : null;
                      final smallPills = <Widget>[
                        Pill(text: 'Unión: $mode', icon: Icons.how_to_reg),
                        if (max != null && max > 0)
                          Pill(
                              text: 'Miembros: $count/$max', icon: Icons.people)
                        else
                          Pill(
                              text: 'Miembros: $count',
                              icon: Icons.people_outline),
                      ];
                      return SolidListTile(
                        title: g.name,
                        bodyBelowTitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (categoryPill != null)
                              SizedBox(
                                width: double.infinity,
                                child: categoryPill,
                              ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: smallPills,
                            ),
                          ],
                        ),
                        leadingIcon: Icons.group_work,
                        onTap: () =>
                            Get.toNamed(AppRoutes.groupDetail, arguments: {
                          'courseId': courseId,
                          'groupId': g.id,
                        }),
                      );
                    }),
                  ],
                ));

      return CoursePageScaffold(
        header: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CourseHeader(
              title: displayTitle,
              subtitle: 'Grupos',
              inactive: isInactive,
            ),
            const SizedBox(height: 8),
            _countPill(label: 'Cantidad', value: list.length.toString()),
          ],
        ),
        sections: [
          if (isTeacher && !isInactive)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.group_add),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.goldAccent,
                  foregroundColor: AppTheme.premiumBlack,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                ),
                onPressed: () => Get.toNamed(AppRoutes.groupCreate, arguments: {
                  'courseId': courseId,
                  'lockCourse': true,
                }),
                label: const Text('NUEVO'),
              ),
            ),
          content,
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
        key: 'categories:course:$courseId',
        ttl: const Duration(seconds: 45),
        action: () => categoryController.loadByCourse(courseId),
        force: force,
      ),
      refresh.run(
        key: 'groups:course:$courseId',
        ttl: const Duration(seconds: 45),
        action: () async {
          final groups = await groupController.loadByCourse(courseId);
          final ids = groups.map((g) => g.id).toList(growable: false);
          if (ids.isNotEmpty) {
            await membershipController.preloadMembershipsForGroups(ids);
            await membershipController.preloadMemberCountsForGroups(ids);
          }
        },
        force: force,
      ),
    ]);
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
