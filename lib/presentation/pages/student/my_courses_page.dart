import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import '../../controllers/enrollment_controller.dart';
import '../../controllers/course_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/course/course_ui_components.dart';
import '../../widgets/revalidation_mixin.dart';
import '../../../core/utils/refresh_manager.dart';
import '../../../core/utils/app_event_bus.dart';

class MyCoursesPage extends StatefulWidget {
  const MyCoursesPage({super.key});

  @override
  State<MyCoursesPage> createState() => _MyCoursesPageState();
}

class _MyCoursesPageState extends State<MyCoursesPage> with RevalidationMixin {
  final enrollmentController = Get.find<EnrollmentController>();
  final courseController = Get.find<CourseController>();
  late final AppEventBus _bus;
  StreamSubscription<Object>? _sub;

  @override
  void initState() {
    super.initState();
    enrollmentController.loadMyEnrollments();
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
    await refresh.run(
      key: 'enrollments:mine',
      ttl: const Duration(seconds: 45),
      action: () => enrollmentController.loadMyEnrollments(),
      force: force,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final list = enrollmentController.myEnrollments;
      final loading = enrollmentController.isLoading.value;
      return CoursePageScaffold(
        header: CourseHeader(
          title: 'Mis cursos',
          subtitle: 'Cursos en los que estás inscrito',
        ),
        sections: [
          if (loading && list.isEmpty)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator()))
          else if (list.isEmpty)
            Center(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppTheme.goldAccent.withOpacity(.35), width: 1),
                ),
                child: const Text('Aún no te has inscrito en cursos'),
              ),
            )
          else
            Column(
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
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
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
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
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
                  );
                }),
              ],
            ),
        ],
      );
    });
  }
}
