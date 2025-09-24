import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../theme/app_theme.dart';
import '../../widgets/course/course_ui_components.dart';
import '../../controllers/course_controller.dart';
import '../../controllers/category_controller.dart';
import '../../controllers/group_controller.dart';
import '../../../domain/models/category.dart';

class GroupCreatePage extends StatefulWidget {
  const GroupCreatePage({super.key});

  @override
  State<GroupCreatePage> createState() => _GroupCreatePageState();
}

class _GroupCreatePageState extends State<GroupCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  String? _selectedCourseId;
  String? _selectedCategoryId;
  bool _lockCourse = false;
  bool _lockCategory = false;

  late final CourseController courseController;
  late final CategoryController categoryController;
  late final GroupController groupController;

  List<Category> _categories = const [];

  @override
  void initState() {
    super.initState();
    courseController = Get.find<CourseController>();
    categoryController = Get.find<CategoryController>();
    groupController = Get.find<GroupController>();
    final args = Get.arguments as Map<String, dynamic>?;
    _selectedCourseId = args?['courseId'] ?? _selectedCourseId;
    _selectedCategoryId = args?['categoryId'] ?? _selectedCategoryId;
    _lockCourse = args?['lockCourse'] == true;
    // Solo bloqueamos categoría si se pide explícitamente; crear grupo desde detalle del curso
    // ya no debe bloquear la categoría (el usuario puede elegir cualquier categoría del curso).
    final explicitLockCategory = args?['lockCategory'] == true;
    _lockCategory = explicitLockCategory;
    courseController.loadMyTeachingCourses();
    if (_selectedCourseId != null && _selectedCourseId!.isNotEmpty) {
      // Cargar categorías; si está bloqueada y aún no está en cache, insertar placeholder temporal
      if (_lockCategory &&
          _selectedCategoryId != null &&
          _selectedCategoryId!.isNotEmpty) {
        final cached =
            categoryController.categoriesByCourse[_selectedCourseId!] ??
                const [];
        final exists = cached.any((c) => c.id == _selectedCategoryId);
        if (!exists) {
          // placeholder con nombre provisional hasta que llegue la real
          setState(() {
            _categories = [
              Category(
                id: _selectedCategoryId!,
                name: 'Cargando categoría...',
                courseId: _selectedCourseId!,
                teacherId: courseController.currentTeacherId ?? 'teacher',
                groupingMethod: 'manual',
                maxMembersPerGroup: null,
                description: null,
                createdAt: DateTime.now(),
                isActive: true,
              ),
            ];
          });
        }
      }
      categoryController.loadByCourse(_selectedCourseId!).then((cats) {
        setState(() {
          _categories = cats;
        });
      });
    } else {
      _categories = const [];
    }
  }

  Future<void> _onCourseChanged(String? courseId) async {
    setState(() {
      _selectedCourseId = courseId;
      _selectedCategoryId = null;
      _categories = const [];
    });
    if (courseId != null) {
      final cats = await categoryController.loadByCourse(courseId);
      setState(() => _categories = cats);
    }
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
        _selectedCourseId!, 'grupos');
    if (!ok) return;
    if (_selectedCategoryId == null) {
      Get.snackbar('Falta categoría', 'Selecciona una categoría',
          backgroundColor: Colors.red[400], colorText: Colors.white);
      return;
    }
    final g = await groupController.createGroup(
      name: _nameCtrl.text.trim(),
      courseId: _selectedCourseId!,
      categoryId: _selectedCategoryId!,
    );
    if (g != null && mounted) {
      Get.snackbar(
        'Grupo creado',
        '"${g.name}" creado correctamente',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppTheme.goldAccent,
        colorText: AppTheme.premiumBlack,
      );
      Navigator.of(context).pop(true);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CoursePageScaffold(
      header: const CourseHeader(
        title: 'Crear grupo',
        subtitle: 'Formulario de creación',
      ),
      sections: [
        SectionCard(
          title: 'Información del grupo',
          leadingIcon: Icons.groups,
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
                    onChanged: _lockCourse ? null : _onCourseChanged,
                  );
                }),
                const SizedBox(height: 12),
                _DropdownField<String>(
                  label: 'Categoría',
                  value: _selectedCategoryId,
                  items: [
                    for (final cat in _categories)
                      DropdownMenuItem(
                        value: cat.id,
                        child: Text(
                          // Si se bloqueó explícitamente, mostramos el texto (o placeholder); si no, siempre el nombre.
                          (_lockCategory && cat.id == _selectedCategoryId)
                              ? (cat.name == 'Cargando categoría...'
                                  ? '...'
                                  : cat.name)
                              : cat.name,
                        ),
                      ),
                  ],
                  onChanged: _lockCategory
                      ? null
                      : (v) => setState(() => _selectedCategoryId = v),
                ),
                const SizedBox(height: 12),
                _TextField(
                  label: 'Nombre del grupo',
                  controller: _nameCtrl,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Ingresa un nombre'
                      : null,
                ),
                const SizedBox(height: 24),
                Obx(() {
                  final loading = groupController.isLoading.value;
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
                })
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
  const _TextField({
    required this.label,
    required this.controller,
    int? maxLines,
    this.validator,
  }) : maxLines = maxLines ?? 1;
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
