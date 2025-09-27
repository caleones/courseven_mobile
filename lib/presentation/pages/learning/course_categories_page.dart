import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import '../../controllers/category_controller.dart';
import '../../../core/config/app_routes.dart';
import '../../controllers/activity_controller.dart';
import '../../controllers/course_controller.dart';
import '../../controllers/group_controller.dart';
import '../../widgets/course/course_ui_components.dart';
import '../../theme/app_theme.dart';
import '../../widgets/revalidation_mixin.dart';
import '../../../core/utils/refresh_manager.dart';
import '../../../core/utils/app_event_bus.dart';

class CourseCategoriesPage extends StatefulWidget {
  const CourseCategoriesPage({super.key});

  @override
  State<CourseCategoriesPage> createState() => _CourseCategoriesPageState();
}

class _CourseCategoriesPageState extends State<CourseCategoriesPage>
    with RevalidationMixin {
  final categoryController = Get.find<CategoryController>();
  final activityController = Get.find<ActivityController>();
  final courseController = Get.find<CourseController>();
  final groupController = Get.find<GroupController>();
  late final String courseId;
  bool _requestedCourseLoad = false;
  late final AppEventBus _bus;
  StreamSubscription<Object>? _sub;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    courseId = args?['courseId'] ?? '';
    if (courseId.isNotEmpty) {
      categoryController.loadByCourse(courseId);
      groupController.loadByCourse(courseId);
    }
    _bus = Get.find<AppEventBus>();
    _sub = _bus.stream.listen((event) {
      if (event is MembershipJoinedEvent && event.courseId == courseId) {
        revalidate(force: true);
      }
      if (event is ActivityChangedEvent && event.courseId == courseId) {
        revalidate(force: true);
      }
    });
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
                          Icon(Icons.category_outlined,
                              size: 42,
                              color: AppTheme.goldAccent.withOpacity(.65)),
                          const SizedBox(height: 12),
                          Text('No hay categorías aún',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(.75),
                              )),
                        ],
                      ),
                    ),
                    if (isTeacher && !isInactive) ...[
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.goldAccent,
                            foregroundColor: AppTheme.premiumBlack,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 14),
                          ),
                          onPressed: () =>
                              Get.toNamed(AppRoutes.categoryCreate, arguments: {
                            'courseId': courseId,
                            'lockCourse': true,
                          }),
                          label: const Text('NUEVA',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ],
                )
              : Column(
                  children: [
                    ...list.map((c) {
                      
                      final pills = <Widget>[];
                      pills.add(Pill(
                          text: 'Agrupación: ${c.groupingMethod}',
                          icon: Icons.group_work));
                      if (c.maxMembersPerGroup != null) {
                        pills.add(Pill(
                            text: 'Máx: ${c.maxMembersPerGroup}',
                            icon: Icons.people));
                      }
                      
                      final groups = Get.find<GroupController>()
                          .groupsByCourse[courseId]
                          ?.where((g) => g.categoryId == c.id)
                          .length;
                      pills.add(Pill(
                          text: 'Grupos: ${groups ?? 0}', icon: Icons.groups));

                      return SolidListTile(
                        title: c.name,
                        bodyBelowTitle: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: pills,
                        ),
                        leadingIcon: Icons.folder_open,
                        goldOutline: false,
                        onTap: () => Get.toNamed(
                          AppRoutes.categoryDetail,
                          arguments: {
                            'courseId': courseId,
                            'categoryId': c.id,
                          },
                        ),
                      );
                    }),
                  ],
                ));

      return CoursePageScaffold(
        header: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CourseHeader(
              title: displayTitle,
              subtitle: 'Categorías',
              inactive: isInactive,
            ),
            const SizedBox(height: 8),
            _countPill(label: 'Cantidad', value: list.length.toString()),
          ],
        ),
        sections: [
          
          if (list.isNotEmpty && isTeacher && !isInactive)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
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
                  icon: const Icon(Icons.add),
                  label: const Text('NUEVA'),
                ),
              ),
            ),
          
          content,
        ],
      );
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
        key: 'categories:course:$courseId',
        ttl: const Duration(seconds: 45),
        action: () => categoryController.loadByCourse(courseId),
        force: force,
      ),
      refresh.run(
        key: 'groups:course:$courseId',
        ttl: const Duration(seconds: 45),
        action: () => groupController.loadByCourse(courseId),
        force: force,
      ),
    ]);
  }

  

  Widget _countPill({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.goldAccent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ',
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: AppTheme.premiumBlack)),
          Text(value,
              style: const TextStyle(
                  fontFamily: 'monospace',
                  color: AppTheme.premiumBlack,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
