import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import '../../controllers/enrollment_controller.dart';
import '../../controllers/course_controller.dart';
import '../../widgets/course/course_ui_components.dart';
import '../../widgets/revalidation_mixin.dart';
import '../../../core/utils/refresh_manager.dart';
import '../../../core/utils/app_event_bus.dart';

class AvailableCoursesPage extends StatefulWidget {
  const AvailableCoursesPage({super.key});

  @override
  State<AvailableCoursesPage> createState() => _AvailableCoursesPageState();
}

class _AvailableCoursesPageState extends State<AvailableCoursesPage>
    with RevalidationMixin {
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
    return CoursePageScaffold(
      header: const CourseHeader(
        title: 'Cursos disponibles',
        subtitle: 'Ingresa un código o selecciona de la lista',
      ),
      sections: const [
        
        Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('Próximamente: exploración de cursos'),
          ),
        ),
      ],
    );
  }
}
