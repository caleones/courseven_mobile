import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/course_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/course/course_ui_components.dart';

class CourseEditPage extends StatefulWidget {
  const CourseEditPage({super.key});

  @override
  State<CourseEditPage> createState() => _CourseEditPageState();
}

class _CourseEditPageState extends State<CourseEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  late final CourseController courseController;
  late final String courseId;

  @override
  void initState() {
    super.initState();
    courseController = Get.find<CourseController>();
    final args = Get.arguments as Map<String, dynamic>?;
    courseId = args?['courseId'] ?? '';
    _load();
  }

  Future<void> _load() async {
    if (courseId.isEmpty) return;
    final c = await courseController.getCourseById(courseId);
    if (c != null) {
      _nameCtrl.text = c.name;
      _descCtrl.text = c.description;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final c = await courseController.getCourseById(courseId);
    if (c == null) return;
    final updated = await courseController.updateCourse(
      c.copyWith(
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
      ),
    );
    if (updated != null && mounted) {
      Get.snackbar(
        'Curso actualizado',
        'Se guardaron los cambios',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppTheme.goldAccent,
        colorText: AppTheme.premiumBlack,
      );
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CoursePageScaffold(
      header: CourseHeader(
        title: 'Editar curso',
        subtitle: 'Actualiza la información del curso',
        inactive: (courseController.coursesCache[courseId]?.isActive == false),
      ),
      sections: [
        SectionCard(
          title: 'Datos básicos',
          count: 0,
          leadingIcon: Icons.edit,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Ingresa un nombre'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                Obx(() {
                  final loading = courseController.isLoading.value;
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.goldAccent,
                        foregroundColor: AppTheme.premiumBlack,
                      ),
                      child: Text(loading ? 'Guardando…' : 'Guardar cambios'),
                    ),
                  );
                }),
                const SizedBox(height: 12),
                FutureBuilder(
                  future: courseController.getCourseById(courseId),
                  builder: (context, snapshot) {
                    final c = snapshot.data;
                    if (c == null) return const SizedBox.shrink();
                    final isActive = c.isActive;
                    final color = isActive ? Colors.red : Colors.green;
                    final label =
                        isActive ? 'Deshabilitar curso' : 'Habilitar curso';
                    return Obx(() {
                      final loading = courseController.isLoading.value;
                      return SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: color,
                            side: BorderSide(color: color),
                          ),
                          onPressed: loading
                              ? null
                              : () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: Text(label),
                                      content: Text(isActive
                                          ? 'Esto deshabilitará el curso. No se podrán crear elementos hasta habilitarlo de nuevo.'
                                          : 'Esto habilitará el curso si no superas el límite de 3 activos.'),
                                      actions: [
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                            child: const Text('Cancelar')),
                                        ElevatedButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, true),
                                            child: Text(label)),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    final result = await courseController
                                        .setCourseActive(courseId, !isActive);
                                    if (result != null) {
                                      // Trigger cache refresh & reactive UI updates
                                      await courseController
                                          .getCourseById(courseId);
                                      courseController.loadMyTeachingCourses();
                                      // Potential: notify listeners/home to recalc counts (handled in future todo items)
                                      await _load();
                                    }
                                  }
                                },
                          child: Text(label),
                        ),
                      );
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
