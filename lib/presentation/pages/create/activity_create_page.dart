import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../theme/app_theme.dart';
import '../../controllers/course_controller.dart';
import '../../controllers/category_controller.dart';
import '../../controllers/activity_controller.dart';
import '../../../domain/models/course_activity.dart';
import '../../widgets/course/course_ui_components.dart';

class ActivityCreatePage extends StatefulWidget {
  const ActivityCreatePage({super.key});

  @override
  State<ActivityCreatePage> createState() => _ActivityCreatePageState();
}

class _ActivityCreatePageState extends State<ActivityCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime? _dueDate;

  String? _selectedCourseId;
  String? _selectedCategoryId;
  bool _lockCourse = false;
  bool _lockCategory = false;
  
  
  
  String? _lockedCourseName;
  String? _lockedCategoryName;

  late final CourseController courseController;
  late final CategoryController categoryController;
  late final ActivityController activityController;

  @override
  void initState() {
    super.initState();
    courseController = Get.find<CourseController>();
    categoryController = Get.find<CategoryController>();
    activityController = Get.find<ActivityController>();

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
        if (mounted && c != null) {
          setState(() => _lockedCourseName = c.name);
        }
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
        if (cat != null) {
          setState(() => _lockedCategoryName = cat.name);
        }
      });
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(
          () => _dueDate = DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCourseId == null || _selectedCourseId!.isEmpty) {
      Get.snackbar('Falta curso', 'Selecciona un curso',
          backgroundColor: Colors.red[400], colorText: Colors.white);
      return;
    }
    
    final courseController = Get.find<CourseController>();
    final ok = await courseController.ensureCourseActiveOrWarn(
        _selectedCourseId!, 'actividades');
    if (!ok) return;
    if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
      Get.snackbar('Falta categoría', 'Selecciona una categoría',
          backgroundColor: Colors.red[400], colorText: Colors.white);
      return;
    }

    final created = await activityController.createActivity(
      CourseActivity(
        id: '',
        title: _titleCtrl.text.trim(),
        description:
            _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        categoryId: _selectedCategoryId!,
        courseId: _selectedCourseId!,
        createdBy: activityController.currentUserId ?? '',
        dueDate: _dueDate,
        createdAt: DateTime.now(),
        isActive: true,
      ),
    );
    if (created != null && mounted) {
      Get.snackbar(
        'Actividad creada',
        '"${created.title}" creada correctamente',
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
        title: 'Crear actividad',
        subtitle: 'Formulario de creación',
      ),
      sections: [
        SectionCard(
          title: 'Información de la actividad',
          leadingIcon: Icons.task_alt,
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
                    onChanged: _lockCourse
                        ? null
                        : (v) {
                            if (v == _selectedCourseId) return; 
                            setState(() {
                              _selectedCourseId = v;
                              _selectedCategoryId = null;
                            });
                            if (v != null) {
                              categoryController.loadByCourse(v);
                            }
                          },
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
                  );
                }),
                const SizedBox(height: 12),
                _TextField(
                  label: 'Título',
                  controller: _titleCtrl,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Ingresa un título'
                      : null,
                ),
                const SizedBox(height: 12),
                _TextField(
                  label: 'Descripción (opcional)',
                  controller: _descCtrl,
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _dueDate == null
                            ? 'Sin fecha límite'
                            : 'Vence: ${_dueDate!.year}-${_dueDate!.month.toString().padLeft(2, '0')}-${_dueDate!.day.toString().padLeft(2, '0')}',
                        style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.8)),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _pickDueDate,
                      icon: const Icon(Icons.event),
                      label: const Text('Elegir fecha'),
                    )
                  ],
                ),
                const SizedBox(height: 24),
                Obx(() {
                  final loading = activityController.isLoading.value;
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
  const _TextField({
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
