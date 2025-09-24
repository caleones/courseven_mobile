import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/config/app_routes.dart';
import '../../controllers/enrollment_controller.dart';
import '../../controllers/course_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/course/course_ui_components.dart';

class AllCoursesPage extends StatefulWidget {
  const AllCoursesPage({super.key});

  @override
  State<AllCoursesPage> createState() => _AllCoursesPageState();
}

class _AllCoursesPageState extends State<AllCoursesPage> {
  bool _showInactive = false; // collapsed by default

  @override
  Widget build(BuildContext context) {
    final mode = (Get.arguments as Map<String, dynamic>?)?['mode'] as String? ??
        'learning';
    final enrollmentController = Get.find<EnrollmentController>();
    final courseController = Get.find<CourseController>();
    final isTeaching = mode == 'teaching';

    Widget _buildCourseRow(BuildContext context, dynamic c, bool isActive) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.15),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (isActive ? AppTheme.goldAccent : AppTheme.dangerRed)
                    .withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.class_,
                color: isActive ? AppTheme.goldAccent : AppTheme.dangerRed,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          c.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (!isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.dangerRed.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border:
                                Border.all(color: AppTheme.dangerRed, width: 1),
                          ),
                          child: const Text(
                            'INACTIVO',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.4,
                              color: AppTheme.dangerRed,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Código: ${c.joinCode}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.65),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Creado: ${c.createdAt.toLocal().toString().substring(0, 16)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.45),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                size: 20),
          ],
        ),
      );
    }

    Widget buildTeaching() {
      return Obx(() {
        final all =
            courseController.teacherCourses.toList(); // includes inactive
        // Without explicit lastLoadTime in controller, just show static text for now
        final relative = 'Actualizado ahora';
        if (courseController.isLoading.value && all.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (all.isEmpty) {
          return const Center(child: Text('No tienes cursos creados aún'));
        }
        final active = all.where((c) => c.isActive).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final inactive = all.where((c) => !c.isActive).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 4, left: 4),
              child: Text(
                'Resumen: ${active.length} activos • ${inactive.length} inactivos',
                style: TextStyle(
                  fontSize: 12.5,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12, left: 4),
              child: Text(
                relative,
                style: TextStyle(
                  fontSize: 11.5,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
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
                  child: InkWell(
                    onTap: () =>
                        Get.toNamed(AppRoutes.courseDetail, arguments: {
                      'courseId': c.id,
                      'asTeacher': true,
                    }),
                    child: _buildCourseRow(context, c, true),
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
                padding: const EdgeInsets.only(top: 4),
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
                    child: InkWell(
                      onTap: () =>
                          Get.toNamed(AppRoutes.courseDetail, arguments: {
                        'courseId': c.id,
                        'asTeacher': true,
                      }),
                      child: _buildCourseRow(context, c, false),
                    ),
                  )),
          ],
        );
      });
    }

    // helper moved above

    Widget buildLearning() {
      return Obx(() {
        final list = enrollmentController.myEnrollments;
        if (enrollmentController.isLoading.value && list.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (list.isEmpty) {
          return const Center(child: Text('Aún no estás inscrito en cursos'));
        }
        return Column(
          children: [
            ...list.map((e) {
              final title = enrollmentController.getCourseTitle(e.courseId);
              final teacher =
                  enrollmentController.getCourseTeacherName(e.courseId);
              final course = courseController.coursesCache[e.courseId];
              final isInactive = course != null && !course.isActive;
              final subtitle = [
                if (teacher.isNotEmpty) teacher,
                'Inscrito: ${e.enrolledAt.toLocal().toString().substring(0, 16)}'
              ].join(' • ');
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => Get.toNamed(AppRoutes.courseDetail,
                      arguments: {'courseId': e.courseId}),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withOpacity(0.15),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: (isInactive
                                    ? AppTheme.dangerRed
                                    : AppTheme.goldAccent)
                                .withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.school,
                              color: isInactive
                                  ? AppTheme.dangerRed
                                  : Colors.orange,
                              size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                    ),
                                  ),
                                  if (isInactive)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.dangerRed
                                            .withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                            color: AppTheme.dangerRed,
                                            width: 1),
                                      ),
                                      child: const Text(
                                        'INACTIVO',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.4,
                                          color: AppTheme.dangerRed,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.65),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.3),
                            size: 20),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      });
    }

    return CoursePageScaffold(
      header: CourseHeader(
        title: isTeaching ? 'Mi enseñanza' : 'Mi aprendizaje',
        subtitle: isTeaching
            ? 'Cursos en los que enseñas'
            : 'Cursos en los que estás inscrito',
        trailingExtras: isTeaching
            ? [
                // Placeholder: composite counts moved below inside sections; header stays concise for now
              ]
            : null,
      ),
      sections: [
        SectionCard(
          title: isTeaching ? 'Cursos creados' : 'Cursos inscritos',
          count: isTeaching
              ? courseController.teacherCourses.length
              : enrollmentController.myEnrollments.length,
          leadingIcon: Icons.library_books,
          child: isTeaching ? buildTeaching() : buildLearning(),
        ),
      ],
    );
  }
}
