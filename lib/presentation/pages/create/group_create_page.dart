import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../../theme/app_theme.dart';
import '../../widgets/course/course_ui_components.dart';
import '../../controllers/course_controller.dart';
import '../../controllers/category_controller.dart';
import '../../controllers/group_controller.dart';

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

  
  String? _lockedCourseName;
  String? _lockedCategoryName;

  late final CourseController courseController;
  late final CategoryController categoryController;
  late final GroupController groupController;

  @override
  void initState() {
    super.initState();
    courseController = Get.find<CourseController>();
    categoryController = Get.find<CategoryController>();
    groupController = Get.find<GroupController>();

    final args = Get.arguments as Map<String, dynamic>?;
    _selectedCourseId = args?['courseId'];
    _selectedCategoryId = args?['categoryId'];
    _lockCourse = args?['lockCourse'] == true;
    _lockCategory = args?['lockCategory'] == true;

    
    courseController.loadMyTeachingCourses();
    
    if (_selectedCourseId != null && _selectedCourseId!.isNotEmpty) {
      categoryController.loadByCourse(_selectedCourseId!);
    }

    
    if (_lockCourse &&
        _selectedCourseId != null &&
        _selectedCourseId!.isNotEmpty) {
      courseController.getCourseById(_selectedCourseId!).then((c) {
        if (mounted && c != null) setState(() => _lockedCourseName = c.name);
      });
    }

    
    if (_lockCategory &&
        _selectedCourseId != null &&
        _selectedCourseId!.isNotEmpty &&
        _selectedCategoryId != null &&
        _selectedCategoryId!.isNotEmpty) {
      categoryController.loadByCourse(_selectedCourseId!).then((cats) {
        if (!mounted) return;
        final cat = cats.firstWhereOrNull((c) => c.id == _selectedCategoryId);
        if (cat != null) setState(() => _lockedCategoryName = cat.name);
      });
    }

    if (kDebugMode) {
      debugPrint(
          '[GROUP_CREATE] args=$args lockCourse=$_lockCourse lockCategory=$_lockCategory course=$_selectedCourseId category=$_selectedCategoryId');
    }
  }

  Future<void> _onCourseChanged(String? courseId) async {
    if (courseId == _selectedCourseId) return;
    setState(() {
      _selectedCourseId = courseId;
      _selectedCategoryId = null; 
      _lockedCategoryName = null;
    });
    if (courseId != null && courseId.isNotEmpty) {
      await categoryController.loadByCourse(courseId);
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
                GetX<CourseController>(builder: (ctrl) {
                  final courses = ctrl.teacherCourses;
                  final List<DropdownMenuItem<String>> items = [
                    for (final c in courses)
                      DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ];
                  if (_lockCourse &&
                      _selectedCourseId != null &&
                      _selectedCourseId!.isNotEmpty &&
                      items.every((e) => e.value != _selectedCourseId)) {
                    items.insert(
                      0,
                      DropdownMenuItem(
                        value: _selectedCourseId,
                        child: Text(
                          _lockedCourseName ?? 'Curso seleccionado',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  }
                  return _DropdownField<String>(
                    label: 'Curso',
                    value: _selectedCourseId,
                    items: items,
                    onChanged: _lockCourse ? null : _onCourseChanged,
                  );
                }),
                const SizedBox(height: 12),
                Obx(() {
                  final map = categoryController.categoriesByCourse; 
                  final _ = map.length; 
                  final cats = _selectedCourseId != null
                      ? (map[_selectedCourseId!] ?? const [])
                      : const [];
                  final List<DropdownMenuItem<String>> items = [
                    for (final cat in cats)
                      DropdownMenuItem(value: cat.id, child: Text(cat.name)),
                  ];
                  if (_lockCategory &&
                      _selectedCategoryId != null &&
                      _selectedCategoryId!.isNotEmpty &&
                      items.every((e) => e.value != _selectedCategoryId)) {
                    items.insert(
                      0,
                      DropdownMenuItem(
                        value: _selectedCategoryId,
                        child: Text(
                          _lockedCategoryName ?? 'Categoría seleccionada',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  }
                  return _DropdownField<String>(
                    label: 'Categoría',
                    value: _selectedCategoryId,
                    items: items,
                    onChanged: _lockCategory
                        ? null
                        : (v) => setState(() => _selectedCategoryId = v),
                    hint: 'Selecciona una categoría',
                  );
                }),
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
  final String? hint;
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    this.onChanged,
    this.hint,
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
              hint: hint != null
                  ? Text(hint!,
                      style: TextStyle(color: Theme.of(context).hintColor))
                  : null,
              onChanged: onChanged,
            ),
          ),
        )
      ],
    );
  }
}
