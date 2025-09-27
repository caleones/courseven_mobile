import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../theme/app_theme.dart';
import '../../controllers/course_controller.dart';
import '../../controllers/category_controller.dart';
import '../../widgets/course/course_ui_components.dart';

class CategoryCreatePage extends StatefulWidget {
  const CategoryCreatePage({super.key});

  @override
  State<CategoryCreatePage> createState() => _CategoryCreatePageState();
}

class _CategoryCreatePageState extends State<CategoryCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _selectedCourseId;
  bool _lockCourse = false;
  String _groupingMethod = 'manual';
  final _maxMembersCtrl = TextEditingController();

  late final CourseController courseController;
  late final CategoryController categoryController;

  @override
  void initState() {
    super.initState();
    courseController = Get.find<CourseController>();
    categoryController = Get.find<CategoryController>();
    final args = Get.arguments as Map<String, dynamic>?;
    _selectedCourseId = args?['courseId'] ?? _selectedCourseId;
    _lockCourse = args?['lockCourse'] == true;
    
    courseController.loadMyTeachingCourses();
    if (_selectedCourseId != null && _selectedCourseId!.isNotEmpty) {
      
      categoryController.loadByCourse(_selectedCourseId!);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _maxMembersCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCourseId == null) {
      Get.snackbar('Falta curso', 'Selecciona un curso',
          backgroundColor: Colors.red[400], colorText: Colors.white);
      return;
    }
    final courseController = Get.find<CourseController>();
    final ok = await courseController.ensureCourseActiveOrWarn(
        _selectedCourseId!, 'categorías');
    if (!ok) return;
    final maxMembers = int.tryParse(_maxMembersCtrl.text.trim());
    final cat = await categoryController.createCategory(
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      courseId: _selectedCourseId!,
      groupingMethod: _groupingMethod,
      maxMembersPerGroup: maxMembers,
    );
    if (cat != null && mounted) {
      Get.snackbar(
        'Categoría creada',
        '"${cat.name}" creada correctamente',
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
      header: const CourseHeader(
        title: 'Crear categoría',
        subtitle: 'Formulario de creación',
      ),
      sections: [
        SectionCard(
          title: 'Información de la categoría',
          leadingIcon: Icons.category,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Obx(() {
                  final courses = courseController.teacherCourses;
                  return _DropdownField<String>(
                    label: 'Curso',
                    value: _selectedCourseId,
                    items: [
                      for (final c in courses)
                        DropdownMenuItem(value: c.id, child: Text(c.name)),
                    ],
                    onChanged: _lockCourse
                        ? null
                        : (v) => setState(() => _selectedCourseId = v),
                  );
                }),
                const SizedBox(height: 12),
                _TextField(
                    label: 'Nombre de la categoría',
                    controller: _nameCtrl,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Ingresa un nombre'
                        : null),
                const SizedBox(height: 12),
                _TextField(
                    label: 'Descripción (opcional)',
                    controller: _descCtrl,
                    maxLines: 3),
                const SizedBox(height: 12),
                _DropdownField<String>(
                  label: 'Método de agrupación',
                  value: _groupingMethod,
                  items: const [
                    DropdownMenuItem(value: 'manual', child: Text('Manual')),
                    DropdownMenuItem(value: 'random', child: Text('Aleatorio')),
                  ],
                  onChanged: (v) =>
                      setState(() => _groupingMethod = v ?? 'manual'),
                ),
                const SizedBox(height: 12),
                _TextField(
                  label: 'Máx. miembros por grupo (opcional)',
                  controller: _maxMembersCtrl,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),
                Obx(() {
                  final loading = categoryController.isLoading.value;
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

class _TextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  const _TextField({
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.validator,
    this.keyboardType,
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
          keyboardType: keyboardType,
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
        )
      ],
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    this.onChanged,
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              isExpanded: true,
              value: value,
              items: items,
              onChanged: onChanged,
            ),
          ),
        )
      ],
    );
  }
}
