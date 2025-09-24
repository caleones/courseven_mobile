import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/category_controller.dart';
import '../../controllers/group_controller.dart';
import '../../controllers/membership_controller.dart';
import '../../controllers/activity_controller.dart';
import '../../controllers/course_controller.dart';
import '../../../core/config/app_routes.dart';
import '../../widgets/course/course_ui_components.dart';

class CategoryGroupsPage extends StatefulWidget {
  const CategoryGroupsPage({super.key});

  @override
  State<CategoryGroupsPage> createState() => _CategoryGroupsPageState();
}

class _CategoryGroupsPageState extends State<CategoryGroupsPage> {
  final categoryController = Get.find<CategoryController>();
  final groupController = Get.find<GroupController>();
  final membershipController = Get.find<MembershipController>();
  final activityController = Get.find<ActivityController>();
  final courseController = Get.find<CourseController>();

  late final String categoryId;
  late final String courseId;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    courseId = args?['courseId'] ?? '';
    categoryId = args?['categoryId'] ?? '';
    if (categoryId.isNotEmpty) {
      if (courseId.isNotEmpty) {
        categoryController.loadByCourse(courseId);
      }
      // Carga de grupos y luego precarga membresías/conteos para evitar condiciones de carrera
      groupController.loadByCategory(categoryId).then((groups) {
        final ids = groups.map((g) => g.id).toList(growable: false);
        if (ids.isEmpty) return;
        membershipController.preloadMembershipsForGroups(ids);
        membershipController.preloadMemberCountsForGroups(ids);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Resolve category for header and settings
      final catList =
          categoryController.categoriesByCourse[courseId] ?? const [];
      dynamic cat;
      for (final c in catList) {
        if ((c as dynamic).id == categoryId) {
          cat = c;
          break;
        }
      }

      // Resolve groups list with fallback by course when map isn't ready yet
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

      final listWidget = groupController.isLoading.value && list.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            )
          : (list.isEmpty
              ? const Center(child: Text('No hay grupos aún'))
              : Column(
                  children: [
                    ...list.map((g) {
                      final gId = (g as dynamic).id as String;
                      final gName = (g as dynamic).name as String? ?? '';
                      final joined =
                          membershipController.myGroupIds.contains(gId);
                      final max = (cat as dynamic)?.maxMembersPerGroup as int?;
                      final count =
                          membershipController.groupMemberCounts[gId] ?? 0;
                      final canJoin = !isRandom &&
                          !isTeacher &&
                          !joined &&
                          ((max == null || max == 0) || count < max);
                      final subtitle = isRandom
                          ? 'Asignación aleatoria por el docente'
                          : 'Unión manual disponible • Miembros: ${max != null && max > 0 ? '$count/$max' : '$count'}';
                      return SolidListTile(
                        title: gName,
                        subtitle: subtitle,
                        leadingIcon: Icons.groups,
                        trailing: isRandom
                            ? const Icon(Icons.lock, color: Colors.grey)
                            : isTeacher
                                ? const Icon(Icons.chevron_right)
                                : joined
                                    ? const Chip(label: Text('Miembro'))
                                    : ElevatedButton(
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
                                                            'Unirme'),
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
                                                } else {
                                                  final err =
                                                      membershipController
                                                          .errorMessage.value;
                                                  if (err.isNotEmpty)
                                                    Get.snackbar('Error', err);
                                                }
                                              }
                                            : null,
                                        child: Text(
                                            canJoin ? 'Unirme' : 'Sin cupo'),
                                      ),
                      );
                    }),
                  ],
                ));

      return CoursePageScaffold(
        header: CourseHeader(
          title: ((cat as dynamic)?.name as String?) ?? 'Categoría',
          subtitle: 'Grupos de la categoría',
          inactive: isInactive,
        ),
        sections: [
          SectionCard(
            title: 'Grupos',
            count: list.length,
            leadingIcon: Icons.groups,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                listWidget,
                const SizedBox(height: 10),
                if (isTeacher) ...[
                  DualActionButtons(
                    primaryLabel: 'Crear actividad',
                    secondaryLabel: 'Crear grupo',
                    primaryIcon: Icons.task_alt,
                    secondaryIcon: Icons.group_add,
                    primaryEnabled: !isInactive,
                    onPrimary: () => Get.toNamed(
                      AppRoutes.activityCreate,
                      arguments: {
                        'courseId': courseId,
                        'categoryId': categoryId,
                        'lockCourse': true,
                        'lockCategory': true,
                      },
                    ),
                    onSecondary: () => Get.toNamed(
                      AppRoutes.groupCreate,
                      arguments: {
                        'courseId': courseId,
                        'categoryId': categoryId,
                        'lockCourse': true,
                        'lockCategory': true,
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    });
  }
}
