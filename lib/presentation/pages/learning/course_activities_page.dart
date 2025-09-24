import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/activity_controller.dart';
import '../../controllers/category_controller.dart';
import '../../controllers/course_controller.dart';
import '../../controllers/enrollment_controller.dart';
import '../../../core/config/app_routes.dart';
import '../../widgets/course/course_ui_components.dart';
import '../../theme/app_theme.dart';

class CourseActivitiesPage extends StatefulWidget {
  const CourseActivitiesPage({super.key});

  @override
  State<CourseActivitiesPage> createState() => _CourseActivitiesPageState();
}

class _CourseActivitiesPageState extends State<CourseActivitiesPage> {
  final activityController = Get.find<ActivityController>();
  final categoryController = Get.find<CategoryController>();
  final enrollmentController = Get.find<EnrollmentController>();
  final courseController = Get.find<CourseController>();
  late final String courseId;
  bool _requestedCourseLoad = false;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    courseId = args?['courseId'] ?? '';
    if (courseId.isNotEmpty) {
      activityController.loadForCourse(courseId);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_requestedCourseLoad &&
        courseId.isNotEmpty &&
        courseController.coursesCache[courseId] == null) {
      _requestedCourseLoad = true;
      courseController.getCourseById(courseId);
    }
    return Obx(() {
      final course = courseController.coursesCache[courseId];
      final myUserId = activityController.currentUserId ?? '';
      final isTeacher = course?.teacherId == myUserId;
      final isInactive = course != null && !course.isActive;
      final displayTitle =
          course?.name ?? enrollmentController.getCourseTitle(courseId);

      final list = activityController.activitiesByCourse[courseId] ?? const [];
      final cats = categoryController.categoriesByCourse[courseId] ?? const [];

      final content = activityController.isLoading.value && list.isEmpty
          ? const Center(
              child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator()))
          : (list.isEmpty
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _emptyCard(context, 'No hay actividades aún'),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add_task),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (isTeacher && !isInactive)
                              ? AppTheme.goldAccent
                              : Theme.of(context)
                                  .disabledColor
                                  .withOpacity(0.1),
                          foregroundColor: AppTheme.premiumBlack,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 14),
                        ),
                        onPressed: (isTeacher && !isInactive)
                            ? () => Get.toNamed(AppRoutes.activityCreate,
                                    arguments: {
                                      'courseId': courseId,
                                      'lockCourse': true,
                                    })?.then((created) {
                                  if (created == true) {
                                    activityController.loadForCourse(courseId);
                                  }
                                })
                            : null,
                        label: const Text('CREAR ACTIVIDAD',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    ...list.map((a) {
                      final cat =
                          cats.firstWhereOrNull((c) => c.id == a.categoryId);
                      return FutureBuilder<String?>(
                        future:
                            activityController.resolveMyGroupNameForActivity(a),
                        builder: (_, snap) {
                          final groupName = snap.data;

                          // Create pills for activity details
                          final pills = <Widget>[];
                          if (cat != null) {
                            pills.add(
                                _simplePill(cat.name, icon: Icons.category));
                          }
                          if (a.dueDate != null) {
                            pills.add(_simplePill(
                                'Vence: ${_fmtDate(a.dueDate!)}',
                                icon: Icons.schedule));
                          } else {
                            pills.add(_simplePill('Sin fecha límite',
                                icon: Icons.schedule_outlined));
                          }
                          if (groupName != null) {
                            pills.add(_simplePill('Tu grupo: $groupName',
                                icon: Icons.group));
                          }

                          // Notification-style tile with pills
                          return _NotificationStyleTile(
                            title: a.title,
                            pills: pills,
                            icon: Icons.task_outlined,
                            iconColor: AppTheme.goldAccent,
                            onTap: () => Get.toNamed(AppRoutes.activityDetail,
                                arguments: {
                                  'courseId': courseId,
                                  'activityId': a.id
                                }),
                          );
                        },
                      );
                    }),
                  ],
                ));

      return CoursePageScaffold(
        header: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CourseHeader(
                title: displayTitle.isEmpty ? 'Curso' : displayTitle,
                subtitle: 'Actividades',
                inactive: isInactive,
              ),
            ),
            const SizedBox(width: 12),
            // Count pill at top-right
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.goldAccent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${list.length}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.premiumBlack,
                ),
              ),
            ),
          ],
        ),
        sections: [
          // External CREATE button when not empty
          if (list.isNotEmpty && isTeacher && !isInactive)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.goldAccent,
                    foregroundColor: AppTheme.premiumBlack,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  onPressed: () =>
                      Get.toNamed(AppRoutes.activityCreate, arguments: {
                    'courseId': courseId,
                    'lockCourse': true,
                  })?.then((created) {
                    if (created == true) {
                      activityController.loadForCourse(courseId);
                    }
                  }),
                  child: const Text('CREAR ACTIVIDAD'),
                ),
              ),
            ),
          // Activities content without SectionCard wrapper
          content,
        ],
      );
    });
  }

  Widget _emptyCard(BuildContext context, String text) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.2)),
        ),
        child: Text(text, textAlign: TextAlign.center),
      ),
    );
  }

  String _fmtDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Widget _simplePill(String text, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.goldAccent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: AppTheme.premiumBlack),
            const SizedBox(width: 4),
          ],
          Text(text,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.premiumBlack)),
        ],
      ),
    );
  }
}

class _NotificationStyleTile extends StatelessWidget {
  final String title;
  final List<Widget> pills;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;

  const _NotificationStyleTile({
    required this.title,
    required this.pills,
    required this.icon,
    required this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: iconColor.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  if (pills.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: pills,
                    ),
                  ],
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
