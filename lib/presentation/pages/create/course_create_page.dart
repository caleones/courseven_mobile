import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../theme/app_theme.dart';
import '../../controllers/course_controller.dart';
import '../../widgets/course/course_ui_components.dart';

class CourseCreatePage extends StatefulWidget {
  const CourseCreatePage({super.key});

  @override
  State<CourseCreatePage> createState() => _CourseCreatePageState();
}

class _CourseCreatePageState extends State<CourseCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  

  late final CourseController courseController;

  @override
  void initState() {
    super.initState();
    courseController = Get.find<CourseController>();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final can = await courseController.canCreateMoreCourses();
    if (!can) {
      Get.snackbar(
        'Límite alcanzado',
        'Solo puedes tener hasta 3 cursos como profesor.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red[400],
        colorText: Colors.white,
      );
      return;
    }

    await courseController.createCourse(
      name: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
    );

    if (courseController.createdCourse.value != null && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CoursePageScaffold(
      header: const CourseHeader(
        title: 'Crear curso',
        subtitle: 'Formulario de creación',
      ),
      sections: [
        SectionCard(
          title: 'Información del curso',
          leadingIcon: Icons.menu_book,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _Field(
                  label: 'Nombre del curso',
                  controller: _titleCtrl,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Ingresa un nombre'
                      : null,
                ),
                const SizedBox(height: 12),
                _Field(
                  label: 'Descripción',
                  controller: _descCtrl,
                  maxLines: 4,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Ingresa una descripción'
                      : null,
                ),
                const SizedBox(height: 24),
                Obx(() {
                  final loading = courseController.isLoading.value;
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.goldAccent,
                        foregroundColor: AppTheme.premiumBlack,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      onPressed: loading ? null : _submit,
                      child: Text(loading ? 'CREANDO...' : 'CREAR'),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;
  final String? Function(String?)? validator;

  const _Field({
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.8))),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color:
                      Theme.of(context).colorScheme.outline.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.goldAccent),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
