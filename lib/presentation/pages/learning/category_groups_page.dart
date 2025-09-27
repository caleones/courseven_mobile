import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import '../../controllers/category_controller.dart';
import '../../controllers/group_controller.dart';
import '../../controllers/membership_controller.dart';
import '../../controllers/activity_controller.dart';
import '../../controllers/course_controller.dart';
import '../../../core/config/app_routes.dart';
import '../../widgets/course/course_ui_components.dart';
import '../../theme/app_theme.dart';
import '../../widgets/revalidation_mixin.dart';
import '../../../core/utils/refresh_manager.dart';
import '../../../core/utils/app_event_bus.dart';

class CategoryGroupsPage extends StatefulWidget {
  const CategoryGroupsPage({super.key});

  @override
  State<CategoryGroupsPage> createState() => _CategoryGroupsPageState();
}

class _CategoryGroupsPageState extends State<CategoryGroupsPage>
    with RevalidationMixin {
  final categoryController = Get.find<CategoryController>();
  final groupController = Get.find<GroupController>();
  final membershipController = Get.find<MembershipController>();
  final activityController = Get.find<ActivityController>();
  final courseController = Get.find<CourseController>();

  late final String categoryId;
  late final String courseId;
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
      if (event is MembershipJoinedEvent) {
        
        if (courseId.isNotEmpty) {
          revalidate(force: true);
        }
      }
      if (event is EnrollmentJoinedEvent && event.courseId == courseId) {
        revalidate(force: true);
      }
      if (event is ActivityChangedEvent && event.courseId == courseId) {
        revalidate(force: true);
      }
    });
    if (categoryId.isNotEmpty) {
      if (courseId.isNotEmpty) {
        categoryController.loadByCourse(courseId);
      }
      groupController.loadByCategory(categoryId).then((groups) {
        final ids = groups.map((g) => g.id).toList(growable: false);
        if (ids.isEmpty) return;
        membershipController.preloadMembershipsForGroups(ids);
        membershipController.preloadMemberCountsForGroups(ids);
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
    if (categoryId.isEmpty) return;
    final refresh = Get.find<RefreshManager>();
    await Future.wait([
      if (courseId.isNotEmpty)
        refresh.run(
          key: 'categories:course:$courseId',
          ttl: const Duration(seconds: 45),
          action: () => categoryController.loadByCourse(courseId),
          force: force,
        ),
      refresh.run(
        key: 'groups:category:$categoryId',
        ttl: const Duration(seconds: 45),
        action: () async {
          final groups = await groupController.loadByCategory(categoryId);
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

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      
      final catList =
          categoryController.categoriesByCourse[courseId] ?? const [];
      dynamic cat;
      for (final c in catList) {
        if ((c as dynamic).id == categoryId) {
          cat = c;
          break;
        }
      }

      
      var list = groupController.groupsByCategory[categoryId] ?? const [];
      if (list.isEmpty) {
        final byCourse = groupController.groupsByCourse[courseId] ?? const [];
        list = byCourse
            .where((g) => (g as dynamic).categoryId == categoryId)
            .toList();
      }

      final grouping = (cat as dynamic)?.groupingMethod;
      final isRandom = (grouping?.toString().toLowerCase() ?? '') == 'random';

      final myUserId = activityController.currentUserId ?? '';
      final course = courseController.coursesCache[courseId];
      final isTeacher = (course?.teacherId ?? '') == myUserId;
      final isInactive = course != null && !course.isActive;

      
      final catGroupIds = list.map((g) => (g as dynamic).id as String).toSet();
      final hasJoinedInCategory =
          membershipController.myGroupIds.any(catGroupIds.contains);

      
      if (!isTeacher && hasJoinedInCategory) {
        list = list
            .where((g) => membershipController.myGroupIds
                .contains((g as dynamic).id as String))
            .toList();
      }

      final listWidget = groupController.isLoading.value && list.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            )
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
                    if (isTeacher && !isInactive) ...[
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.group_add),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.goldAccent,
                            foregroundColor: AppTheme.premiumBlack,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 14),
                          ),
                          onPressed: () => Get.toNamed(
                            AppRoutes.groupCreate,
                            arguments: {
                              'courseId': courseId,
                              'categoryId': categoryId,
                              'lockCourse': true,
                              'lockCategory': true,
                            },
                          ),
                          label: const Text('NUEVO',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ],
                )
              : Column(
                  children: [
                    if (isTeacher && !isInactive) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.group_add),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.goldAccent,
                            foregroundColor: AppTheme.premiumBlack,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          onPressed: () => Get.toNamed(
                            AppRoutes.groupCreate,
                            arguments: {
                              'courseId': courseId,
                              'categoryId': categoryId,
                              'lockCourse': true,
                              'lockCategory': true,
                            },
                          ),
                          label: const Text('NUEVO'),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    ...list.map((g) {
                      final gId = (g as dynamic).id as String;
                      final gName = (g as dynamic).name as String? ?? '';
                      final joined =
                          membershipController.myGroupIds.contains(gId);
                      final max = (cat as dynamic)?.maxMembersPerGroup as int?;
                      final count =
                          membershipController.groupMemberCounts[gId] ?? 0;
                      final blockedByCategory = hasJoinedInCategory &&
                          !joined; 
                      final canJoin = !isRandom &&
                          !isTeacher &&
                          !joined &&
                          !blockedByCategory &&
                          ((max == null || max == 0) || count < max);
                      final pills = <Widget>[
                        Pill(
                          text: 'Unión: ${isRandom ? 'aleatoria' : 'manual'}',
                          icon: Icons.how_to_reg,
                        ),
                        if (max != null && max > 0)
                          Pill(
                              text: 'Miembros: $count/$max', icon: Icons.people)
                        else
                          Pill(
                              text: 'Miembros: $count',
                              icon: Icons.people_outline),
                      ];
                      return SolidListTile(
                        title: gName,
                        bodyBelowTitle: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: pills,
                        ),
                        leadingIcon: Icons.groups,
                        trailing: isRandom
                            ? const Icon(Icons.lock, color: Colors.grey)
                            : isTeacher
                                ? const Icon(Icons.chevron_right)
                                : joined
                                    ? const Chip(label: Text('Miembro'))
                                    : ElevatedButton.icon(
                                        icon:
                                            const Icon(Icons.person_add_alt_1),
                                        onPressed: canJoin
                                            ? () async {
                                                final ok =
                                                    await showDialog<bool>(
                                                  context: context,
                                                  builder: (ctx) => AlertDialog(
                                                    title: const Text(
                                                        'Unirse al grupo'),
                                                    content: Text(
                                                        '¿Deseas unirte a "$gName"? Esto te unirá a la categoría "${((cat as dynamic)?.name as String?) ?? ''}".'),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                ctx, false),
                                                        child: const Text(
                                                            'Cancelar'),
                                                      ),
                                                      ElevatedButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                ctx, true),
                                                        child: const Text(
                                                            'UNIRME'),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                                if (ok != true) return;
                                                final m =
                                                    await membershipController
                                                        .joinGroup(gId);
                                                if (m != null) {
                                                  Get.snackbar('¡Listo!',
                                                      'Te uniste a $gName');
                                                  
                                                  await membershipController
                                                      .getMemberCount(gId);
                                                  membershipController
                                                      .preloadMembershipsForGroups(
                                                          catGroupIds.toList());
                                                  membershipController
                                                      .preloadMemberCountsForGroups(
                                                          catGroupIds.toList());
                                                } else {
                                                  final err =
                                                      membershipController
                                                          .errorMessage.value;
                                                  if (err.isNotEmpty)
                                                    Get.snackbar('Error', err);
                                                }
                                              }
                                            : null,
                                        label: Text(
                                          canJoin
                                              ? 'UNIRME'
                                              : (blockedByCategory
                                                  ? 'No disponible'
                                                  : 'Sin cupo'),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ),
                        onTap: isTeacher
                            ? () =>
                                Get.toNamed(AppRoutes.groupDetail, arguments: {
                                  'courseId': courseId,
                                  'groupId': gId,
                                })
                            : null,
                      );
                    }),
                    
                  ],
                ));

      return CoursePageScaffold(
        header: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CourseHeader(
              title: ((cat as dynamic)?.name as String?) ?? 'Categoría',
              subtitle: 'Grupos de la categoría',
              inactive: isInactive,
            ),
            const SizedBox(height: 8),
            _countPill(label: 'Cantidad', value: list.length.toString()),
          ],
        ),
        sections: [
          
          listWidget,
        ],
      );
    });
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
