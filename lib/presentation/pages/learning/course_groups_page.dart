import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/group_controller.dart';
import '../../controllers/activity_controller.dart';
import '../../../core/config/app_routes.dart';
import '../../controllers/course_controller.dart';
import '../../widgets/course/course_ui_components.dart';
import '../../theme/app_theme.dart';

class CourseGroupsPage extends StatefulWidget {
  const CourseGroupsPage({super.key});

  @override
  State<CourseGroupsPage> createState() => _CourseGroupsPageState();
}

class _CourseGroupsPageState extends State<CourseGroupsPage> {
  final groupController = Get.find<GroupController>();
  final activityController = Get.find<ActivityController>();
  final courseController = Get.find<CourseController>();
  late final String courseId;
  bool _requestedCourseLoad = false;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    courseId = args?['courseId'] ?? '';
    if (courseId.isNotEmpty) groupController.loadByCourse(courseId);
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
      final displayTitle = course?.name ?? 'Curso';

      final list = groupController.groupsByCourse[courseId] ?? const [];
      final content = groupController.isLoading.value && list.isEmpty
          ? const Center(
              child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator()))
          : (list.isEmpty
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 26),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppTheme.goldAccent.withOpacity(.35),
                            width: 1),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.blur_circular,
                              size: 42,
                              color: AppTheme.goldAccent.withOpacity(.65)),
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
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.group_add),
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
                            ? () =>
                                Get.toNamed(AppRoutes.groupCreate, arguments: {
                                  'courseId': courseId,
                                  'lockCourse': true,
                                })
                            : null,
                        label: const Text('Crear grupo',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    ...list.map((g) => SolidListTile(
                          title: g.name,
                          leadingIcon: Icons.group_work,
                        )),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.group_add),
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
                            ? () =>
                                Get.toNamed(AppRoutes.groupCreate, arguments: {
                                  'courseId': courseId,
                                  'lockCourse': true,
                                })
                            : null,
                        label: const Text('Crear grupo',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ));

      return CoursePageScaffold(
        header: CourseHeader(
          title: displayTitle,
          subtitle: 'Grupos',
          inactive: isInactive,
        ),
        sections: [
          SectionCard(
            title: 'Grupos',
            count: list.length,
            leadingIcon: Icons.groups,
            child: content,
          ),
        ],
      );
    });
  }
}
