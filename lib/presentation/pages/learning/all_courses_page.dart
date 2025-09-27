import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import '../../../core/config/app_routes.dart';
import '../../controllers/enrollment_controller.dart';
import '../../controllers/course_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/course/course_ui_components.dart';
import '../../widgets/revalidation_mixin.dart';
import '../../../core/utils/refresh_manager.dart';
import '../../../core/utils/app_event_bus.dart';

class AllCoursesPage extends StatefulWidget {
  const AllCoursesPage({super.key});

  @override
  State<AllCoursesPage> createState() => _AllCoursesPageState();
}

class _AllCoursesPageState extends State<AllCoursesPage>
    with RevalidationMixin {
  bool _showInactive = false; 
  late final AppEventBus _bus;
  StreamSubscription<Object>? _sub;

  @override
  void initState() {
    super.initState();
    _bus = Get.find<AppEventBus>();
    _sub = _bus.stream.listen((event) {
      if (event is EnrollmentJoinedEvent) {
        revalidate(force: true);
      }
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
    final refresh = Get.find<RefreshManager>();
    final mode = (Get.arguments as Map<String, dynamic>?)?['mode'] as String? ??
        'learning';
    final enrollmentController = Get.find<EnrollmentController>();
    final courseController = Get.find<CourseController>();
    if (mode == 'teaching') {
      await refresh.run(
        key: 'courses:teaching',
        ttl: const Duration(seconds: 45),
        action: () => courseController.loadMyTeachingCourses(),
        force: force,
      );
    } else {
      await refresh.run(
        key: 'enrollments:mine',
        ttl: const Duration(seconds: 45),
        action: () => enrollmentController.loadMyEnrollments(),
        force: force,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = (Get.arguments as Map<String, dynamic>?)?['mode'] as String? ??
        'learning';
    final enrollmentController = Get.find<EnrollmentController>();
    final courseController = Get.find<CourseController>();
    final isTeaching = mode == 'teaching';
    

    Widget buildTeaching() {
      return Obx(() {
        final all =
            courseController.teacherCourses.toList(); 
        
        if (courseController.isLoading.value && all.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (all.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 26),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.goldAccent.withOpacity(.35)),
            ),
            child: Text('No tienes cursos creados aún',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
          );
        }
        final active = all.where((c) => c.isActive).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final inactive = all.where((c) => !c.isActive).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (active.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 4, top: 4),
                child: Text(
                  'Activos (${active.length})',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.65),
                  ),
                ),
              ),
            ...active.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SolidListTile(
                    title: c.name,
                    leadingIcon: Icons.bookmark,
                    leadingIconColor: AppTheme.goldAccent,
                    outlineColor: AppTheme.goldAccent.withOpacity(.45),
                    bodyBelowTitle: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Pill(
                            text: 'Código: ${c.joinCode}',
                            icon: Icons.qr_code_2),
                        Pill(
                          text:
                              'Creado: ${c.createdAt.toLocal().toString().substring(0, 16)}',
                          icon: Icons.schedule,
                        ),
                      ],
                    ),
                    onTap: () =>
                        Get.toNamed(AppRoutes.courseDetail, arguments: {
                      'courseId': c.id,
                      'asTeacher': true,
                    }),
                  ),
                )),
            if (active.isNotEmpty && inactive.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: Theme.of(context).dividerColor.withOpacity(0.25),
                ),
              ),
            if (inactive.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 2),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => setState(() => _showInactive = !_showInactive),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showInactive
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: AppTheme.dangerRed.withOpacity(0.85),
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Inactivos (${inactive.length})',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                          color: AppTheme.dangerRed.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_showInactive)
              ...inactive.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 12, top: 12),
                    child: SolidListTile(
                      title: c.name,
                      leadingIcon: Icons.bookmark,
                      leadingIconColor: AppTheme.dangerRed,
                      outlineColor: AppTheme.dangerRed.withOpacity(.6),
                      
                      onTap: () =>
                          Get.toNamed(AppRoutes.courseDetail, arguments: {
                        'courseId': c.id,
                        'asTeacher': true,
                      }),
                    ),
                  )),
          ],
        );
      });
    }

    

    Widget buildLearning() {
      return Obx(() {
        final list = enrollmentController.myEnrollments;
        if (enrollmentController.isLoading.value && list.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (list.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeaderSlim(
                  title: 'Cursos inscritos', icon: Icons.school),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 26),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: AppTheme.goldAccent.withOpacity(.35)),
                ),
                child: Text('Aún no estás inscrito en cursos',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium),
              ),
            ],
          );
        }
        
        final active = list.where((e) {
          final c = courseController.coursesCache[e.courseId];
          return c == null || c.isActive;
        }).toList();
        final inactive = list.where((e) {
          final c = courseController.coursesCache[e.courseId];
          return c != null && !c.isActive;
        }).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeaderSlim(
              title: 'Cursos inscritos',
              count: list.length,
              icon: Icons.school,
            ),
            ...active.map((e) {
              final title = enrollmentController.getCourseTitle(e.courseId);
              final teacher =
                  enrollmentController.getCourseTeacherName(e.courseId);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SolidListTile(
                  title: title,
                  leadingIcon: Icons.school,
                  bodyBelowTitle: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (teacher.isNotEmpty)
                        Pill(text: teacher, icon: Icons.person_outline),
                      Pill(
                        text:
                            'Inscrito: ${e.enrolledAt.toLocal().toString().substring(0, 16)}',
                        icon: Icons.event_available,
                      ),
                    ],
                  ),
                  onTap: () => Get.toNamed(AppRoutes.courseDetail,
                      arguments: {'courseId': e.courseId}),
                ),
              );
            }),
            if (active.isNotEmpty && inactive.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: Theme.of(context).dividerColor.withOpacity(0.25),
                ),
              ),
            if (inactive.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 2),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => setState(() => _showInactive = !_showInactive),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showInactive
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: AppTheme.dangerRed.withOpacity(0.85),
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Inactivos (${inactive.length})',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                          color: AppTheme.dangerRed.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_showInactive)
              ...inactive.map((e) {
                final title = enrollmentController.getCourseTitle(e.courseId);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12, top: 12),
                  child: SolidListTile(
                    title: title,
                    leadingIcon: Icons.school,
                    leadingIconColor: AppTheme.dangerRed,
                    outlineColor: AppTheme.dangerRed.withOpacity(.6),
                    onTap: () => Get.toNamed(AppRoutes.courseDetail,
                        arguments: {'courseId': e.courseId}),
                  ),
                );
              }),
          ],
        );
      });
    }

    return CoursePageScaffold(
      header: CourseHeader(
        title: isTeaching
            ? 'Cursos en los que enseñas'
            : 'Cursos en los que estás inscrito',
        subtitle: isTeaching ? 'Mi enseñanza' : 'Mi aprendizaje',
      ),
      sections: [
        
        if (isTeaching) buildTeaching() else buildLearning(),
      ],
    );
  }
}
