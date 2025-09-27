import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:get/get.dart';

import '../../../core/config/app_routes.dart';
import '../../controllers/activity_controller.dart';
import '../../controllers/category_controller.dart';
import '../../controllers/course_controller.dart';
import '../../controllers/enrollment_controller.dart';
import '../../controllers/group_controller.dart';
import '../../controllers/membership_controller.dart';
import '../../widgets/inactive_gate.dart';
import '../../theme/app_theme.dart';
import '../../widgets/course/course_ui_components.dart';
import '../../widgets/revalidation_mixin.dart';
import '../../../core/utils/refresh_manager.dart';
import '../../../core/utils/app_event_bus.dart';

class CourseDetailPage extends StatefulWidget {
  const CourseDetailPage({super.key});

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage>
    with RevalidationMixin {
  late final String courseId;
  bool _requestedCourseLoad = false;

  final enrollmentController = Get.find<EnrollmentController>();
  final courseController = Get.find<CourseController>();
  final categoryController = Get.find<CategoryController>();
  final groupController = Get.find<GroupController>();
  final membershipController = Get.find<MembershipController>();
  final activityController = Get.find<ActivityController>();
  late final AppEventBus _bus;
  StreamSubscription<Object>? _sub;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    courseId = args?['courseId'] ?? '';
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
      courseController.getCourseById(courseId);
      categoryController.loadByCourse(courseId);
      activityController.loadForCourse(courseId);
      groupController.loadByCourse(courseId).then((groups) {
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
      refresh.run(
        key: 'enrollCount:course:$courseId',
        ttl: const Duration(seconds: 30),
        action: () => enrollmentController
            .loadEnrollmentCountForCourse(courseId, force: true),
        force: force,
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final myUserId = activityController.currentUserId ?? '';
    if (!_requestedCourseLoad &&
        courseId.isNotEmpty &&
        courseController.coursesCache[courseId] == null) {
      _requestedCourseLoad = true;
      courseController.getCourseById(courseId);
    }
    return Obx(() {
      final cachedTitle = enrollmentController.getCourseTitle(courseId);
      final course = courseController.coursesCache[courseId];
      if (course == null) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      final isTeacher = course.teacherId == myUserId;
      final isInactive = !course.isActive;
      final displayTitle = course.name.isNotEmpty
          ? course.name
          : (cachedTitle.isNotEmpty ? cachedTitle : 'Curso');

      final activityCount =
          activityController.activitiesByCourse[courseId]?.length ?? 0;
      final categoryCount =
          categoryController.categoriesByCourse[courseId]?.length ?? 0;
      final groupCount = groupController.groupsByCourse[courseId]?.length ?? 0;
      final reviewActivityIds =
          (activityController.activitiesByCourse[courseId] ?? const [])
              .where((a) => a.reviewing && !a.privateReview)
              .map((a) => a.id)
              .toList(growable: false);
      final showPeerReviewSection = isTeacher || reviewActivityIds.isNotEmpty;

      enrollmentController.loadEnrollmentCountForCourse(courseId);
      final enrollmentCount = enrollmentController.enrollmentCountFor(courseId);

      return CoursePageScaffold(
        header: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CourseHeader(
              title: displayTitle,
              subtitle: isTeacher
                  ? 'Continúa enseñando'
                  : 'Continúa tu aprendizaje en',
              showEdit: isTeacher,
              inactive: isInactive,
              onEdit: () => Get.toNamed(AppRoutes.courseEdit,
                  arguments: {'courseId': courseId}),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: _metaRow(course.joinCode, enrollmentCount,
                  loading: enrollmentController.isLoadingCount(courseId)),
            ),
          ],
        ),
        sections: [
          if (isInactive) _inactiveBanner(isTeacher),
          if (showPeerReviewSection)
            SectionCard(
              title: 'Peer Review',
              leadingIcon: Icons.analytics_outlined,
              child: _peerReviewSection(
                isTeacher: isTeacher,
                reviewActivityIds: reviewActivityIds,
              ),
            ),
          SectionCard(
            title: 'Actividades',
            count: activityCount,
            leadingIcon: Icons.task_alt,
            child: _activitiesSection(isTeacher, isInactive),
          ),
          SectionCard(
            title: 'Categorías',
            count: categoryCount,
            leadingIcon: Icons.category,
            child: _categoriesSection(isTeacher, isInactive),
          ),
          SectionCard(
            title: 'Grupos',
            count: groupCount,
            leadingIcon: Icons.groups,
            child: _groupsSection(isTeacher, isInactive),
          ),
        ],
      );
    });
  }

  Widget _peerReviewSection({
    required bool isTeacher,
    required List<String> reviewActivityIds,
  }) {
    final theme = Theme.of(context);
    final reviewCount = reviewActivityIds.length;
    final groups = groupController.groupsByCourse[courseId] ?? const [];
    final myGroup = !isTeacher
        ? groups.firstWhereOrNull(
            (g) => membershipController.myGroupIds.contains(g.id))
        : null;
    final children = <Widget>[];

    if (isTeacher) {
      children.add(
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.analytics_outlined),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
            onPressed: reviewCount == 0
                ? null
                : () =>
                    Get.toNamed(AppRoutes.peerReviewCourseSummary, arguments: {
                      'courseId': courseId,
                      'activityIds': reviewActivityIds,
                    }),
            label: const Text('RESULTADOS'),
          ),
        ),
      );
      children.add(const SizedBox(height: 12));
      children.add(Text(
        reviewCount == 0
            ? 'Aún no hay actividades públicas de peer review en este curso.'
            : 'Incluye $reviewCount ${reviewCount == 1 ? 'actividad' : 'actividades'} con peer review público.',
        style: theme.textTheme.bodySmall
            ?.copyWith(color: theme.colorScheme.onSurface.withOpacity(.7)),
      ));
    } else {
      if (reviewCount == 0) {
        children.add(Text(
          'Aún no hay actividades públicas de peer review en este curso.',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurface.withOpacity(.7)),
        ));
      } else if (myGroup == null) {
        children.add(Text(
          'Únete a un grupo para ver el promedio de tu grupo.',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurface.withOpacity(.7)),
        ));
      } else {
        children.add(
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.groups),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
              onPressed: () => Get.toNamed(
                AppRoutes.peerReviewGroupSummary,
                arguments: {
                  'courseId': courseId,
                  'groupId': myGroup.id,
                  'activityIds': reviewActivityIds,
                  'groupName': myGroup.name,
                },
              ),
              label: const Text('PROMEDIO DE MI GRUPO'),
            ),
          ),
        );
        children.add(const SizedBox(height: 12));
        children.add(Text(
          'Actividades consideradas: $reviewCount.',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurface.withOpacity(.65)),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < children.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == children.length - 1 ? 0 : 8),
            child: children[i],
          ),
      ],
    );
  }

  Widget _inactiveBanner(bool isTeacher) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isTeacher)
                  Text(
                    'Este curso está inhabilitado. No puedes crear actividades, categorías o grupos hasta habilitarlo.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.orange[300]),
                  )
                else
                  Text(
                    'Este curso está inhabilitado. Por ahora no puedes realizar acciones en este curso.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.orange[300]),
                  ),
                if (isTeacher)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Habilitar curso'),
                            content: const Text(
                                '¿Deseas habilitar este curso ahora?'),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancelar')),
                              ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Habilitar')),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          final updated = await courseController
                              .setCourseActive(courseId, true);
                          if (updated != null) {
                            enrollmentController.overrideCourseTitle(
                                courseId, updated.name);
                          }
                        }
                      },
                      child: const Text('Habilitar ahora'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _activitiesSection(bool isTeacher, bool isInactive) {
    return InactiveGate(
      inactive: isInactive,
      child: Obx(() {
        final acts = activityController.previewForCourse(courseId, 3);

        if (activityController.isLoading.value && acts.isEmpty) {
          return const Center(
              child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator()));
        }
        final cats =
            categoryController.categoriesByCourse[courseId] ?? const [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isTeacher)
              DualActionButtons(
                primaryLabel: 'NUEVA',
                secondaryLabel: 'VER TODAS',
                primaryIcon: Icons.add_task,
                secondaryIcon: Icons.visibility,
                primaryEnabled: isTeacher && !isInactive,
                onPrimary: () => Get.toNamed(AppRoutes.activityCreate,
                    arguments: {'courseId': courseId, 'lockCourse': true}),
                onSecondary: () => Get.toNamed(AppRoutes.courseActivities,
                    arguments: {'courseId': courseId}),
              )
            else
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
                  onPressed: () => Get.toNamed(AppRoutes.courseActivities,
                      arguments: {'courseId': courseId}),
                  label: const Text('VER TODAS'),
                ),
              ),
            const SizedBox(height: 12),
            if (acts.isEmpty)
              _spiderEmptyCard('No hay actividades aún')
            else
              ...acts.asMap().entries.map((entry) {
                final idx = entry.key;
                final a = entry.value;
                final cat = cats.firstWhereOrNull((c) => c.id == a.categoryId);
                final dueDateStr =
                    a.dueDate != null ? _fmtDate(a.dueDate!) : null;
                return FutureBuilder<String?>(
                  future: activityController.resolveMyGroupNameForActivity(a),
                  builder: (_, snap) {
                    final groupName = snap.data;
                    final pills = <Widget>[];
                    if (cat != null)
                      pills.add(Pill(text: cat.name, icon: Icons.category));
                    pills.add(Pill(
                        text: dueDateStr != null
                            ? 'Vence: $dueDateStr'
                            : 'Sin fecha límite',
                        icon: Icons.schedule));
                    if (groupName != null)
                      pills.add(Pill(
                          text: 'Tu grupo: $groupName', icon: Icons.group));
                    return FadeSlideIn(
                      index: idx,
                      child: SolidListTile(
                        title: a.title,
                        bodyBelowTitle:
                            pills.isNotEmpty ? _verticalPills(pills) : null,
                        leadingIcon: Icons.task_outlined,
                        goldOutline: false,
                        dense: true,
                        onTap: () => Get.toNamed(AppRoutes.activityDetail,
                            arguments: {
                              'courseId': courseId,
                              'activityId': a.id
                            }),
                      ),
                    );
                  },
                );
              }),
          ],
        );
      }),
    );
  }

  Widget _categoriesSection(bool isTeacher, bool isInactive) {
    return InactiveGate(
      inactive: isInactive,
      child: Obx(() {
        final list =
            categoryController.categoriesByCourse[courseId] ?? const [];
        final preview = list.take(3).toList();
        if (categoryController.isLoading.value && list.isEmpty) {
          return const Center(
              child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator()));
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isTeacher)
              DualActionButtons(
                primaryLabel: 'NUEVA',
                secondaryLabel: 'VER TODAS',
                primaryIcon: Icons.add,
                secondaryIcon: Icons.visibility,
                primaryEnabled: isTeacher && !isInactive,
                onPrimary: () => Get.toNamed(AppRoutes.categoryCreate,
                    arguments: {'courseId': courseId, 'lockCourse': true}),
                onSecondary: () => Get.toNamed(AppRoutes.courseCategories,
                    arguments: {'courseId': courseId}),
              )
            else
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
                  onPressed: () => Get.toNamed(AppRoutes.courseCategories,
                      arguments: {'courseId': courseId}),
                  label: const Text('VER TODAS'),
                ),
              ),
            const SizedBox(height: 12),
            if (preview.isEmpty)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 26),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppTheme.goldAccent.withOpacity(.35), width: 1),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.category_outlined,
                        size: 42, color: AppTheme.goldAccent.withOpacity(.65)),
                    const SizedBox(height: 12),
                    Text('No hay categorías aún',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(.75))),
                  ],
                ),
              )
            else
              ...preview.asMap().entries.map((entry) {
                final idx = entry.key;
                final c = entry.value;
                final pills = <Widget>[
                  Pill(
                      text: 'Agrupación: ${c.groupingMethod}',
                      icon: Icons.group_work)
                ];
                if (c.maxMembersPerGroup != null) {
                  pills.add(Pill(
                      text: 'Máx: ${c.maxMembersPerGroup}',
                      icon: Icons.people));
                }
                return FadeSlideIn(
                  index: idx,
                  child: SolidListTile(
                    title: c.name,
                    bodyBelowTitle: _verticalPills(pills),
                    leadingIcon: Icons.folder_open,
                    goldOutline: false,
                    dense: true,
                    onTap: () => Get.toNamed(AppRoutes.categoryDetail,
                        arguments: {'courseId': courseId, 'categoryId': c.id}),
                  ),
                );
              }),
          ],
        );
      }),
    );
  }

  Widget _groupsSection(bool isTeacher, bool isInactive) {
    return InactiveGate(
      inactive: isInactive,
      child: Obx(() {
        final list = groupController.groupsByCourse[courseId] ?? const [];
        var preview = list.take(3).toList();
        if (groupController.isLoading.value && list.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }
        final emptyState = Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 26),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: Theme.of(context).dividerColor.withOpacity(.25),
                width: 1),
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
                        .withOpacity(.75),
                  )),
              const SizedBox(height: 6),
            ],
          ),
        );

        final cats =
            categoryController.categoriesByCourse[courseId] ?? const [];

        if (!isTeacher && membershipController.myGroupIds.isNotEmpty) {
          final joinedByCategory = <String, String>{};
          for (final g in list) {
            if (membershipController.myGroupIds.contains(g.id)) {
              joinedByCategory[g.categoryId] = g.id;
            }
          }
          if (joinedByCategory.isNotEmpty) {
            preview = preview.where((g) {
              final keepId = joinedByCategory[g.categoryId];
              return keepId == null || keepId == g.id;
            }).toList();
          }
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isTeacher)
              DualActionButtons(
                primaryLabel: 'NUEVO',
                secondaryLabel: 'VER TODOS',
                primaryIcon: Icons.group_add,
                secondaryIcon: Icons.visibility,
                primaryEnabled: isTeacher && !isInactive,
                onPrimary: () => Get.toNamed(AppRoutes.groupCreate,
                    arguments: {'courseId': courseId, 'lockCourse': true}),
                onSecondary: () => Get.toNamed(AppRoutes.courseGroups,
                    arguments: {'courseId': courseId}),
              )
            else
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
                  onPressed: () => Get.toNamed(AppRoutes.courseGroups,
                      arguments: {'courseId': courseId}),
                  label: const Text('VER TODOS'),
                ),
              ),
            const SizedBox(height: 12),
            if (preview.isEmpty)
              emptyState
            else
              ...preview.asMap().entries.map((entry) {
                final idx = entry.key;
                final g = entry.value;
                final cat = cats.firstWhereOrNull((c) => c.id == g.categoryId);
                final mode = cat?.groupingMethod.toLowerCase() ?? 'manual';
                final max = cat?.maxMembersPerGroup;
                final count = membershipController.groupMemberCounts[g.id] ?? 0;

                return FadeSlideIn(
                  index: idx,
                  child: SolidListTile(
                    title: g.name,
                    bodyBelowTitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (cat != null)
                          SizedBox(
                            width: double.infinity,
                            child: Pill(
                              text: 'Categoría: ${cat.name}',
                              icon: Icons.folder_open,
                            ),
                          ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Pill(
                                text:
                                    'Unión: ${mode == 'random' ? 'aleatoria' : 'manual'}',
                                icon: Icons.how_to_reg),
                            if (max != null && max > 0)
                              Pill(
                                  text: 'Miembros: $count/$max',
                                  icon: Icons.people)
                            else
                              Pill(
                                  text: 'Miembros: $count',
                                  icon: Icons.people_outline),
                          ],
                        ),
                      ],
                    ),
                    leadingIcon: Icons.group_work,
                    goldOutline: false,
                    dense: true,
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () {
                      Get.toNamed(AppRoutes.groupDetail, arguments: {
                        'courseId': courseId,
                        'groupId': g.id,
                      });
                    },
                  ),
                );
              }).toList(),
            const SizedBox(height: 16),
            Divider(color: AppTheme.goldAccent.withOpacity(.35), height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () =>
                    Get.toNamed(AppRoutes.courseStudents, arguments: {
                  'courseId': courseId,
                }),
                icon: const Icon(Icons.people_alt),
                label: const Text('VER ESTUDIANTES'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _spiderEmptyCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 26),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppTheme.goldAccent.withOpacity(.35), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SpiderWebIcon(
            size: 42,
            color: AppTheme.goldAccent.withOpacity(.75),
          ),
          const SizedBox(height: 12),
          Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(.8),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Widget _metaRow(String joinCode, int enrollmentCount,
      {bool loading = false}) {
    return Wrap(
      spacing: 10,
      runSpacing: 6,
      children: [
        _solidPill(label: 'Código', value: joinCode.isEmpty ? '—' : joinCode),
        _solidPill(
          label: 'Estudiantes',
          value: loading ? 'Cargando…' : '$enrollmentCount',
        ),
      ],
    );
  }

  Widget _solidPill({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.goldAccent,
        borderRadius: BorderRadius.circular(20),
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
          Text('$label: ',
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: AppTheme.premiumBlack)),
          Text(value,
              style: const TextStyle(
                  fontFamily: 'monospace',
                  letterSpacing: .5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.premiumBlack)),
        ],
      ),
    );
  }

  Widget _verticalPills(List<Widget> pills) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < pills.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == pills.length - 1 ? 0 : 6),
              child: pills[i],
            ),
        ],
      ),
    );
  }
}

class _SpiderWebIcon extends StatelessWidget {
  final double size;
  final Color color;
  const _SpiderWebIcon({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SpiderWebPainter(color),
      ),
    );
  }
}

class _SpiderWebPainter extends CustomPainter {
  final Color color;
  _SpiderWebPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (final r in [radius * .3, radius * .55, radius * .8]) {
      canvas.drawCircle(center, r, paint);
    }

    const spokes = 6;
    for (int i = 0; i < spokes; i++) {
      final angle = (i * (360 / spokes)) * math.pi / 180;
      final end = Offset(center.dx + radius * .9 * math.cos(angle),
          center.dy + radius * .9 * math.sin(angle));
      canvas.drawLine(center, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SpiderWebPainter oldDelegate) =>
      oldDelegate.color != color;
}
