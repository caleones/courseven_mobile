import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import '../../controllers/course_controller.dart';
import '../../controllers/enrollment_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/course/course_ui_components.dart';
import '../../widgets/revalidation_mixin.dart';
import '../../../core/utils/refresh_manager.dart';
import '../../../core/utils/app_event_bus.dart';
import '../../../core/config/app_routes.dart';


class CourseStudentsPage extends StatefulWidget {
  const CourseStudentsPage({super.key});

  @override
  State<CourseStudentsPage> createState() => _CourseStudentsPageState();
}

class _CourseStudentsPageState extends State<CourseStudentsPage>
    with RevalidationMixin {
  late final String courseId;
  final enrollmentController = Get.find<EnrollmentController>();
  final courseController = Get.find<CourseController>();
  bool _requestedCourse = false;
  late final AppEventBus _bus;
  StreamSubscription<Object>? _sub;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    courseId = args?['courseId'] ?? '';
    if (courseId.isNotEmpty) {
      
      enrollmentController.loadEnrollmentsForCourse(courseId);
    }
    _bus = Get.find<AppEventBus>();
    _sub = _bus.stream.listen((event) {
      if (event is EnrollmentJoinedEvent && event.courseId == courseId) {
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
    if (courseId.isEmpty) return;
    final refresh = Get.find<RefreshManager>();
    await Future.wait([
      refresh.run(
        key: 'enrollments:list:$courseId',
        ttl: const Duration(seconds: 45),
        action: () => enrollmentController.loadEnrollmentsForCourse(courseId),
        force: force,
      ),
      refresh.run(
        key: 'enrollments:count:$courseId',
        ttl: const Duration(seconds: 30),
        action: () => enrollmentController
            .loadEnrollmentCountForCourse(courseId, force: true),
        force: force,
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    if (!_requestedCourse &&
        courseId.isNotEmpty &&
        courseController.coursesCache[courseId] == null) {
      _requestedCourse = true;
      courseController.getCourseById(courseId);
    }
    return Obx(() {
      final course = courseController.coursesCache[courseId];
      final title = course?.name ?? 'Curso';
      final isLoading = enrollmentController.isLoadingCourse(courseId);
      final enrollments = enrollmentController.enrollmentsFor(courseId);

      return CoursePageScaffold(
        header: CourseHeader(
          title: title,
          subtitle: 'Estudiantes',
          showEdit: false,
          inactive: !(course?.isActive ?? true),
        ),
        sections: [
          if (isLoading && enrollments.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            )
          else if (enrollments.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 26),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.goldAccent.withOpacity(.35)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline,
                      size: 42, color: AppTheme.goldAccent.withOpacity(.65)),
                  const SizedBox(height: 12),
                  Text('No hay estudiantes inscritos',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(.75))),
                ],
              ),
            )
          else ...[
            ...enrollments
                .map((e) => _studentTile(e.studentId, e.enrolledAt))
                .toList(),
          ],
        ],
      );
    });
  }

  Widget _studentTile(String studentId, DateTime enrolledAt) {
    final name = enrollmentController.userName(studentId);
    final email = enrollmentController.userEmail(studentId);
    return SolidListTile(
      title: name,
      subtitle: email.isNotEmpty ? email : 'Inscrito: ${_fmtDate(enrolledAt)}',
      leadingIcon: Icons.person_outline,
      dense: true,
      goldOutline: true,
      marginBottom: 6, 
      onTap: () {
        Get.toNamed(AppRoutes.studentDetail, arguments: {
          'courseId': courseId,
          'studentId': studentId,
        });
      },
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
