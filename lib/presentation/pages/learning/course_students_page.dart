import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/course_controller.dart';
import '../../controllers/enrollment_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/course/course_ui_components.dart';

/// Página que lista todos los estudiantes inscritos en un curso.
class CourseStudentsPage extends StatefulWidget {
  const CourseStudentsPage({super.key});

  @override
  State<CourseStudentsPage> createState() => _CourseStudentsPageState();
}

class _CourseStudentsPageState extends State<CourseStudentsPage> {
  late final String courseId;
  final enrollmentController = Get.find<EnrollmentController>();
  final courseController = Get.find<CourseController>();
  bool _requestedCourse = false;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    courseId = args?['courseId'] ?? '';
    if (courseId.isNotEmpty) {
      // Prefetch full enrollments list
      enrollmentController.loadEnrollmentsForCourse(courseId);
    }
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
          subtitle: 'Estudiantes inscritos en',
          showEdit: false,
          inactive: !(course?.isActive ?? true),
        ),
        sections: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.goldAccent.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.people_alt,
                        size: 20, color: AppTheme.goldAccent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Listado de estudiantes',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (isLoading)
                      const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                  ],
                ),
                const SizedBox(height: 14),
                if (!isLoading && enrollments.isEmpty)
                  Text('No hay estudiantes inscritos todavía.',
                      style: Theme.of(context).textTheme.bodyMedium),
                if (enrollments.isNotEmpty)
                  ...enrollments
                      .map((e) => _studentTile(e.studentId, e.enrolledAt))
                      .toList(),
                if (!isLoading)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => enrollmentController
                          .loadEnrollmentsForCourse(courseId, force: true),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Refrescar'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _studentTile(String studentId, DateTime enrolledAt) {
    final name = enrollmentController.userName(studentId);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.goldAccent.withOpacity(.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_outline,
              color: AppTheme.goldAccent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15.5)),
                const SizedBox(height: 4),
                Text('Inscrito: ${_fmtDate(enrolledAt)}',
                    style: TextStyle(
                        fontSize: 12.5,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(.65))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
