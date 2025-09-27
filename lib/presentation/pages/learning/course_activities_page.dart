import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:get/get.dart';
import 'dart:async';
import '../../controllers/activity_controller.dart';
import '../../controllers/category_controller.dart';
import '../../controllers/course_controller.dart';
import '../../controllers/enrollment_controller.dart';
import '../../../core/config/app_routes.dart';
import '../../widgets/course/course_ui_components.dart';
import '../../theme/app_theme.dart';
import '../../widgets/revalidation_mixin.dart';
import '../../../core/utils/refresh_manager.dart';
import '../../../core/utils/app_event_bus.dart';

class CourseActivitiesPage extends StatefulWidget {
  const CourseActivitiesPage({super.key});

  @override
  State<CourseActivitiesPage> createState() => _CourseActivitiesPageState();
}

class _CourseActivitiesPageState extends State<CourseActivitiesPage>
    with RevalidationMixin {
  final activityController = Get.find<ActivityController>();
  final categoryController = Get.find<CategoryController>();
  final enrollmentController = Get.find<EnrollmentController>();
  final courseController = Get.find<CourseController>();
  late final String courseId;
  bool _requestedCourseLoad = false;
  late final AppEventBus _bus;
  StreamSubscription<Object>? _sub;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    courseId = args?['courseId'] ?? '';
    _bus = Get.find<AppEventBus>();
    _sub = _bus.stream.listen((event) {
      if (event is EnrollmentJoinedEvent && event.courseId == courseId) {
        revalidate(force: true);
      }
      if (event is MembershipJoinedEvent && event.courseId == courseId) {
        revalidate(force: true);
      }
      if (event is ActivityChangedEvent && event.courseId == courseId) {
        revalidate(force: true);
      }
    });
    if (courseId.isNotEmpty) {
      activityController.loadForCourse(courseId);
    }
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
        key: 'activities:course:$courseId',
        ttl: const Duration(seconds: 20),
        action: () => activityController.loadForCourse(courseId),
        force: force,
      ),
      refresh.run(
        key: 'categories:course:$courseId',
        ttl: const Duration(seconds: 45),
        action: () => categoryController.loadByCourse(courseId),
        force: force,
      ),
    ]);
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
                    _spiderEmptyState(context, 'No hay actividades aún'),
                    if (isTeacher && !isInactive) ...[
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add_task),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.goldAccent,
                            foregroundColor: AppTheme.premiumBlack,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 14),
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
                          label: const Text('NUEVA',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
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

                          
                          final pills = <Widget>[];
                          if (cat != null) {
                            pills.add(
                                Pill(text: cat.name, icon: Icons.category));
                          }
                          if (a.dueDate != null) {
                            pills.add(Pill(
                                text: 'Vence: ${_fmtDate(a.dueDate!)}',
                                icon: Icons.schedule));
                          } else {
                            pills.add(Pill(
                                text: 'Sin fecha límite',
                                icon: Icons.schedule_outlined));
                          }
                          if (groupName != null) {
                            pills.add(Pill(
                                text: 'Tu grupo: $groupName',
                                icon: Icons.group));
                          }

                          
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
        header: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CourseHeader(
              title: displayTitle.isEmpty ? 'Curso' : displayTitle,
              subtitle: 'Actividades',
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.add_task, color: AppTheme.premiumBlack),
                      SizedBox(width: 8),
                      Text('NUEVA'),
                    ],
                  ),
                ),
              ),
            ),
          
          content,
        ],
      );
    });
  }

  

  String _fmtDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
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

  
  Widget _spiderEmptyState(BuildContext context, String text) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppTheme.goldAccent.withOpacity(0.35), width: 1),
        ),
        child: Column(
          children: const [
            _SpiderWebIcon(size: 42),
            SizedBox(height: 12),
            Text('No hay actividades aún',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
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

class _SpiderWebIcon extends StatelessWidget {
  final double size;
  const _SpiderWebIcon({this.size = 42});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SpiderWebPainter(AppTheme.goldAccent),
      ),
    );
  }
}

class _SpiderWebPainter extends CustomPainter {
  final Color color;
  _SpiderWebPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;
    final paint = Paint()
      ..color = color.withOpacity(.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (final r in [radius * .3, radius * .55, radius * .8]) {
      canvas.drawCircle(center, r, paint);
    }

    const spokes = 6;
    for (int i = 0; i < spokes; i++) {
      final angle = (i * (360 / spokes)) * math.pi / 180;
      final end = Offset(center.dx + radius * .9 * math.cos(angle),
          center.dy + radius * .9 * math.sin(angle));
      canvas.drawLine(center, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SpiderWebPainter oldDelegate) =>
      oldDelegate.color != color;
}
