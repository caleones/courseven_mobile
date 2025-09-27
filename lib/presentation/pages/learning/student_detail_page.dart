import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/activity_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/course_controller.dart';
import '../../controllers/enrollment_controller.dart';
import '../../widgets/course/course_ui_components.dart';
import '../../../core/config/app_routes.dart';
import '../../../domain/models/course_activity.dart';

class StudentDetailPage extends StatefulWidget {
  final String courseId;
  final String studentId;
  const StudentDetailPage(
      {super.key, required this.courseId, required this.studentId});

  @override
  State<StudentDetailPage> createState() => _StudentDetailPageState();
}

class _StudentDetailPageState extends State<StudentDetailPage> {
  final enrollmentController = Get.find<EnrollmentController>();
  final courseController = Get.find<CourseController>();
  final activityController = Get.find<ActivityController>();
  final authController = Get.find<AuthController>();

  bool _loadingUser = false;
  bool _prefetchedActivities = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (widget.courseId.isNotEmpty) {
      courseController.getCourseById(widget.courseId);
      enrollmentController.loadEnrollmentsForCourse(widget.courseId);
      if (!_prefetchedActivities) {
        _prefetchedActivities = true;
        activityController.loadForCourse(widget.courseId);
      }
    }
    setState(() => _loadingUser = true);
    await enrollmentController.ensureUserLoaded(widget.studentId);
    setState(() => _loadingUser = false);
  }

  bool get _isTeacherViewer {
    final course = courseController.coursesCache[widget.courseId];
    final currentUserId = authController.currentUser?.id;
    return course != null &&
        currentUserId != null &&
        course.teacherId == currentUserId;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final course = courseController.coursesCache[widget.courseId];
      final user = enrollmentController.cachedUser(widget.studentId);
      final enrollments = enrollmentController.enrollmentsFor(widget.courseId);
      final enrollment =
          enrollments.firstWhereOrNull((e) => e.studentId == widget.studentId);
      final name = enrollmentController.userName(widget.studentId);
      final email = enrollmentController.userEmail(widget.studentId);
      final username = user?.username ?? '';
      final studentCode = user?.studentId ?? '';
      final createdAt = user?.createdAt;
      final isActive = user?.isActive ?? true;
      final joinedAt = enrollment?.enrolledAt;
      final activities =
          activityController.activitiesByCourse[widget.courseId] ?? const [];
      final isLoadingActivities = activityController.isLoading.value;

      final headerSubtitle = course != null
          ? 'Miembro del curso "${course.name}"'
          : 'Detalle de Estudiante';

      return CoursePageScaffold(
        header: CourseHeader(
          title: name,
          subtitle: headerSubtitle,
          showEdit: false,
        ),
        showDock: false,
        sections: [
          _infoSection(
            isLoading: _loadingUser,
            email: email,
            username: username,
            studentCode: studentCode,
            createdAt: createdAt,
            joinedAt: joinedAt,
            isActive: isActive,
          ),
          if (_isTeacherViewer)
            _resultsSection(context, activities, enrollments.isNotEmpty,
                isLoadingActivities),
        ],
      );
    });
  }

  Widget _infoSection({
    required bool isLoading,
    required String email,
    required String username,
    required String studentCode,
    required DateTime? createdAt,
    required DateTime? joinedAt,
    required bool isActive,
  }) {
    if (isLoading) {
      return const Center(
          child: Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: CircularProgressIndicator(),
      ));
    }
    return SectionCard(
      title: 'Información básica',
      leadingIcon: Icons.person_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _kv('Correo', email.isNotEmpty ? email : 'No disponible'),
          _kv('Usuario', username.isNotEmpty ? username : 'No disponible'),
          _kv('Código estudiante',
              studentCode.isNotEmpty ? studentCode : 'No disponible'),
          _kv('Cuenta desde',
              createdAt != null ? _fmtDate(createdAt) : 'No disponible'),
          _kv('Inscrito al curso',
              joinedAt != null ? _fmtDate(joinedAt) : 'No disponible'),
          _kv('Estado', isActive ? 'Activa' : 'Inactiva'),
        ],
      ),
    );
  }

  Widget _resultsSection(BuildContext context, List<CourseActivity> activities,
      bool hasEnrollment, bool isLoadingActivities) {
    final hasPeerReviewActivities =
        activities.any((a) => a.reviewing && !a.privateReview);
    String message;
    if (isLoadingActivities) {
      message = 'Cargando actividades de peer review...';
    } else if (hasPeerReviewActivities) {
      message = 'Consulta los resultados de peer review recibidos.';
    } else if (hasEnrollment) {
      message = 'Aún no hay actividades con peer review público.';
    } else {
      message = 'El estudiante no aparece inscrito en este curso.';
    }
    return Card(
      margin: const EdgeInsets.only(top: 20),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            ElevatedButton.icon(
              onPressed: hasPeerReviewActivities && !isLoadingActivities
                  ? () {
                      Get.toNamed(AppRoutes.studentCoursePeerResults,
                          arguments: {
                            'courseId': widget.courseId,
                            'studentId': widget.studentId,
                          });
                    }
                  : null,
              icon: const Icon(Icons.bar_chart),
              label: const Text('RESULTADOS'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kv(String key, String value) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(key,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: onSurface.withOpacity(.75))),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
