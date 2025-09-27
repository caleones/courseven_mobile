import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/config/app_routes.dart';
import '../../controllers/activity_controller.dart';
import '../../controllers/category_controller.dart';
import '../../controllers/course_controller.dart';
import '../../widgets/course/course_ui_components.dart';
import '../../theme/app_theme.dart';
import '../../../domain/models/course_activity.dart';

class ActivityEditPage extends StatefulWidget {
  const ActivityEditPage({super.key});
  @override
  State<ActivityEditPage> createState() => _ActivityEditPageState();
}

class _ActivityEditPageState extends State<ActivityEditPage> {
  late final String courseId;
  late final String activityId;
  final activityController = Get.find<ActivityController>();
  final categoryController = Get.find<CategoryController>();
  final courseController = Get.find<CourseController>();

  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  DateTime? _dueDate;
  bool _isActive = true;
  bool _reviewing = false;
  bool _privateReview = false; 

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    courseId = args?['courseId'] ?? '';
    activityId = args?['activityId'] ?? '';
    if (courseId.isNotEmpty) {
      activityController.loadForCourse(courseId);
      categoryController.loadByCourse(courseId);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final activities = activityController.activitiesByCourse[courseId] ?? [];
      final activity = activities.firstWhereOrNull((a) => a.id == activityId);
      if (activity == null) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      _ensureSeed(activity);
      final isTeacher = courseController.coursesCache[courseId]?.teacherId ==
          activityController.currentUserId;
      if (!isTeacher) {
        return Scaffold(
          body: Center(
            child: Text('Solo el profesor puede editar',
                style: Theme.of(context).textTheme.bodyMedium),
          ),
        );
      }
      return CoursePageScaffold(
        header: CourseHeader(
          title: 'Editar',
          subtitle: 'Actividad',
          showEdit: false,
        ),
        sections: [
          _form(activity),
        ],
      );
    });
  }

  void _ensureSeed(CourseActivity activity) {
    if (_titleCtrl.text.isEmpty) {
      _titleCtrl.text = activity.title;
      _descriptionCtrl.text = activity.description ?? '';
      _dueDate = activity.dueDate;
      _isActive = activity.isActive;
      _reviewing = activity.reviewing;
      _privateReview = activity.privateReview;
    }
  }

  Widget _form(CourseActivity original) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Título'),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Requerido' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descriptionCtrl,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Descripción'),
          ),
          const SizedBox(height: 12),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DatePill(dueDate: _dueDate),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dueDate ?? now,
                    firstDate: now.subtract(const Duration(days: 365)),
                    lastDate: now.add(const Duration(days: 365 * 3)),
                    helpText: 'Selecciona fecha límite',
                  );
                  if (picked != null) {
                    setState(() => _dueDate = picked);
                  }
                },
                icon: const Icon(Icons.event),
                label: const Text('Elegir fecha'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Actividad activa'),
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
          ),
          const SizedBox(height: 12),
          if (_reviewing)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Resultados privados (solo profesor)'),
                  subtitle: const Text(
                      'Si está desactivado los estudiantes verán sus resultados cuando completen todas sus evaluaciones.'),
                  value: _privateReview,
                  onChanged: (v) => setState(() => _privateReview = v),
                ),
                const SizedBox(height: 8),
                Text('Peer review activo',
                    style: Theme.of(context).textTheme.labelMedium),
              ],
            )
          else
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.goldAccent.withOpacity(.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.group,
                          size: 18, color: AppTheme.goldAccent),
                      const SizedBox(width: 8),
                      Text('Peer Review no activado',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                      'Al activar peer review desde el detalle de la actividad, por defecto será público salvo que elijas hacerlo privado.',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          const SizedBox(height: 20),
          SaveButton(onPressed: () => _submit(original)),
        ],
      ),
    );
  }

  

  Future<void> _submit(CourseActivity original) async {
    if (!_formKey.currentState!.validate()) return;
    final updated = original.copyWith(
      title: _titleCtrl.text.trim(),
      description: _descriptionCtrl.text.trim().isEmpty
          ? null
          : _descriptionCtrl.text.trim(),
      dueDate: _dueDate,
      isActive: _isActive,
      
      privateReview: _reviewing ? _privateReview : original.privateReview,
    );
    final res = await activityController.updateActivity(updated);
    if (res != null) {
      Get.offNamed(AppRoutes.activityDetail,
          arguments: {'courseId': courseId, 'activityId': res.id});
      Get.snackbar('Guardado', 'Cambios aplicados');
    } else {
      final err = activityController.errorMessage.value;
      if (err.isNotEmpty) Get.snackbar('Error', err);
    }
  }
}
