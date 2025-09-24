// (Legacy header removed during redesign)
import 'package:flutter/material.dart';
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

/// Rediseño visual del detalle del curso con:
///  - Encabezado personalizado (sin AppBar estándar)
///  - Título multilinea y pill de edición a la derecha
///  - Tarjetas seccionales sólidas (Actividades, Categorías, Grupos)
///  - Botones de acción estilizados y consistentes
///  - Dock de navegación inferior reinstalado
class CourseDetailPage extends StatefulWidget {
  const CourseDetailPage({super.key});

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  late final String courseId;
  bool _requestedCourseLoad = false;

  final enrollmentController = Get.find<EnrollmentController>();
  final courseController = Get.find<CourseController>();
  final categoryController = Get.find<CategoryController>();
  final groupController = Get.find<GroupController>();
  final membershipController = Get.find<MembershipController>();
  final activityController = Get.find<ActivityController>();

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    courseId = args?['courseId'] ?? '';
    if (courseId.isNotEmpty) {
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

      // Trigger enrollment count lazy load (only once)
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

  // Legacy header & section card replaced by CourseHeader and SectionCard components.

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
                Text(
                  'Este curso está inhabilitado. No puedes crear actividades, categorías o grupos hasta habilitarlo.',
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
        final allActs =
            activityController.activitiesByCourse[courseId] ?? const [];
        final peerActs = allActs.where((a) => a.reviewing).toList();
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
            DualActionButtons(
              primaryLabel: 'CREAR ACTIVIDAD',
              secondaryLabel: 'VER TODAS',
              primaryIcon: Icons.add_task,
              secondaryIcon: Icons.visibility,
              primaryEnabled: isTeacher && !isInactive,
              onPrimary: () => Get.toNamed(AppRoutes.activityCreate,
                  arguments: {'courseId': courseId, 'lockCourse': true}),
              onSecondary: () => Get.toNamed(AppRoutes.courseActivities,
                  arguments: {'courseId': courseId}),
            ),
            if (isTeacher && peerActs.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.analytics_outlined),
                  label: const Text('RESUMEN GLOBAL PEER REVIEW'),
                  onPressed: () => Get.toNamed(
                    AppRoutes.peerReviewCourseSummary,
                    arguments: {
                      'courseId': courseId,
                      'activityIds': peerActs.map((a) => a.id).toList(),
                    },
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (acts.isEmpty)
              _placeholderCard('No hay actividades aún')
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
                      pills.add(_simplePill(cat.name, icon: Icons.category));
                    pills.add(_simplePill(
                        dueDateStr != null
                            ? 'Vence: $dueDateStr'
                            : 'Sin fecha límite',
                        icon: Icons.schedule));
                    if (groupName != null)
                      pills.add(_simplePill('Tu grupo: $groupName',
                          icon: Icons.group));
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
            DualActionButtons(
              primaryLabel: 'CREAR CATEGORÍA',
              secondaryLabel: 'VER TODAS',
              primaryIcon: Icons.add,
              secondaryIcon: Icons.visibility,
              primaryEnabled: isTeacher && !isInactive,
              onPrimary: () => Get.toNamed(AppRoutes.categoryCreate,
                  arguments: {'courseId': courseId, 'lockCourse': true}),
              onSecondary: () => Get.toNamed(AppRoutes.courseCategories,
                  arguments: {'courseId': courseId}),
            ),
            const SizedBox(height: 12),
            if (preview.isEmpty)
              _placeholderCard('No hay categorías aún')
            else
              ...preview.asMap().entries.map((entry) {
                final idx = entry.key;
                final c = entry.value;
                final pills = <Widget>[
                  _simplePill('Agrupación: ${c.groupingMethod}',
                      icon: Icons.group_work)
                ];
                if (c.maxMembersPerGroup != null) {
                  pills.add(_simplePill('Máx: ${c.maxMembersPerGroup}',
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
        final preview = list.take(3).toList();
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
              Text('Crea el primero para organizar equipos',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(.55),
                  )),
            ],
          ),
        );

        final cats =
            categoryController.categoriesByCourse[courseId] ?? const [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DualActionButtons(
              primaryLabel: 'CREAR GRUPO',
              secondaryLabel: 'VER TODOS',
              primaryIcon: Icons.group_add,
              secondaryIcon: Icons.visibility,
              primaryEnabled: isTeacher && !isInactive,
              onPrimary: () => Get.toNamed(AppRoutes.groupCreate,
                  arguments: {'courseId': courseId, 'lockCourse': true}),
              onSecondary: () => Get.toNamed(AppRoutes.courseGroups,
                  arguments: {'courseId': courseId}),
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
                final joined = membershipController.myGroupIds.contains(g.id);
                final count = membershipController.groupMemberCounts[g.id] ?? 0;
                final subtitle = [
                  if (cat != null) 'Categoría: ${cat.name}',
                  'Unión: ${mode == 'random' ? 'aleatoria' : 'manual'}',
                  if (max != null && max > 0)
                    'Miembros: $count/$max'
                  else
                    'Miembros: $count'
                ].join(' • ');
                final canJoin = !isTeacher &&
                    mode == 'manual' &&
                    !joined &&
                    ((max == null || max == 0) || count < max);
                return FadeSlideIn(
                  index: idx,
                  child: SolidListTile(
                    title: g.name,
                    subtitle: subtitle,
                    leadingIcon: Icons.group_work,
                    goldOutline: false,
                    dense: true,
                    trailing: canJoin
                        ? const Text(
                            'Toca para unirte',
                            style: TextStyle(
                              color: AppTheme.successGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : const Icon(Icons.chevron_right, size: 18),
                    onTap: () async {
                      if (!canJoin) return;
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Unirse al grupo'),
                          content: Text(
                              '¿Deseas unirte al grupo "${g.name}"? Esto te unirá a la categoría "${cat?.name ?? ''}".'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancelar'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.successGreen,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Unirme'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await membershipController.joinGroup(g.id);
                      }
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

  Widget _placeholderCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: Theme.of(context).dividerColor.withOpacity(0.18)),
      ),
      child: Text(text),
    );
  }

  // Removed old tile & button helpers in favor of SolidListTile and DualActionButtons.

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Widget _metaRow(String joinCode, int enrollmentCount,
      {bool loading = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _solidPill(label: 'Código', value: joinCode.isEmpty ? '—' : joinCode),
        const SizedBox(width: 10),
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

  Widget _simplePill(String text, {IconData? icon, Color? color}) {
    // Standardized pill: fixed min height, consistent horizontal padding, single-line ellipsis.
    final bg = (color ?? AppTheme.goldAccent);
    const double pillHeight = 28; // unify across all pills
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: pillHeight),
      child: Container(
        margin: const EdgeInsets.only(right: 6, bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(pillHeight / 2),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: Colors.grey.shade700),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade800,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Vertical stack of pills under title
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
