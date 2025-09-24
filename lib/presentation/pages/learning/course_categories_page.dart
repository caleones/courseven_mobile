import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/category_controller.dart';
import '../../../core/config/app_routes.dart';
import '../../controllers/activity_controller.dart';
import '../../controllers/course_controller.dart';
import '../../widgets/course/course_ui_components.dart';
import '../../theme/app_theme.dart';

class CourseCategoriesPage extends StatefulWidget {
  const CourseCategoriesPage({super.key});

  @override
  State<CourseCategoriesPage> createState() => _CourseCategoriesPageState();
}

class _CourseCategoriesPageState extends State<CourseCategoriesPage> {
  final categoryController = Get.find<CategoryController>();
  final activityController = Get.find<ActivityController>();
  final courseController = Get.find<CourseController>();
  late final String courseId;
  bool _requestedCourseLoad = false;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    courseId = args?['courseId'] ?? '';
    if (courseId.isNotEmpty) categoryController.loadByCourse(courseId);
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

      final list = categoryController.categoriesByCourse[courseId] ?? const [];
      final content = categoryController.isLoading.value && list.isEmpty
          ? const Center(
              child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator()))
          : (list.isEmpty
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(child: Text('No hay categorías aún')),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add),
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
                            ? () => Get.toNamed(AppRoutes.categoryCreate,
                                    arguments: {
                                      'courseId': courseId,
                                      'lockCourse': true,
                                    })
                            : null,
                        label: const Text('CREAR CATEGORÍA',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    ...list.map((c) {
                      // Create pills for category details
                      final pills = <Widget>[];
                      pills.add(_simplePill('Agrupación: ${c.groupingMethod}',
                          icon: Icons.group_work));
                      if (c.maxMembersPerGroup != null) {
                        pills.add(_simplePill('Máx: ${c.maxMembersPerGroup}',
                            icon: Icons.people));
                      }

                      return SolidListTile(
                        title: c.name,
                        subtitle:
                            null, // Remove subtitle since we're using pills
                        trailing: pills.isNotEmpty
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ...pills.map((pill) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 4),
                                        child: pill,
                                      )),
                                ],
                              )
                            : const Icon(Icons.chevron_right),
                        leadingIcon: Icons.folder_open,
                        onTap: () =>
                            Get.toNamed(AppRoutes.categoryGroups, arguments: {
                          'courseId': courseId,
                          'categoryId': c.id,
                        }),
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
                title: displayTitle,
                subtitle: 'Categorías',
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
                      Get.toNamed(AppRoutes.categoryCreate, arguments: {
                    'courseId': courseId,
                    'lockCourse': true,
                  }),
                  child: const Text('CREAR CATEGORÍA'),
                ),
              ),
            ),
          // Categories content without SectionCard wrapper
          content,
        ],
      );
    });
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
