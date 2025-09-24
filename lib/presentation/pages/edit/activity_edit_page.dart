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
          Row(
            children: [
              // Due date as pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.goldAccent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule,
                        size: 16, color: AppTheme.premiumBlack),
                    const SizedBox(width: 6),
                    Text(
                      _dueDate != null
                          ? 'Vence: ${_fmtDate(_dueDate!)}'
                          : 'Sin fecha límite',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.premiumBlack,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
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
              if (_dueDate != null)
                IconButton(
                  tooltip: 'Quitar fecha',
                  onPressed: () => setState(() => _dueDate = null),
                  icon: const Icon(Icons.close),
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
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.save),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldAccent,
                foregroundColor: AppTheme.premiumBlack,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
              onPressed: () => _submit(original),
              label: const Text('GUARDAR'),
            ),
          )
        ],
      ),
    );
  }

  // Danger zone removed per new requirement (delete flow not needed here).

  Future<void> _submit(CourseActivity original) async {
    if (!_formKey.currentState!.validate()) return;
    final updated = original.copyWith(
      title: _titleCtrl.text.trim(),
      description: _descriptionCtrl.text.trim().isEmpty
          ? null
          : _descriptionCtrl.text.trim(),
      dueDate: _dueDate,
      isActive: _isActive,
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

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
