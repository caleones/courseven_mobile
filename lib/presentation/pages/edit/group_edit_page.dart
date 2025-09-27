import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../domain/models/group.dart';
import '../../controllers/group_controller.dart';
import '../../controllers/category_controller.dart';
import '../../controllers/course_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/course/course_ui_components.dart';

class GroupEditPage extends StatefulWidget {
  const GroupEditPage({super.key});
  @override
  State<GroupEditPage> createState() => _GroupEditPageState();
}

class _GroupEditPageState extends State<GroupEditPage> {
  final groupController = Get.find<GroupController>();
  final categoryController = Get.find<CategoryController>();
  final courseController = Get.find<CourseController>();

  late final String courseId;
  late final String groupId;
  Group? _group;
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  String? _selectedCategoryId;
  bool _loadingInit = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    courseId = args?['courseId'] ?? '';
    groupId = args?['groupId'] ?? '';
    _init();
  }

  Future<void> _init() async {
    if (groupController.groupsByCourse[courseId] == null) {
      await groupController.loadByCourse(courseId);
    }
    if (categoryController.categoriesByCourse[courseId] == null) {
      await categoryController.loadByCourse(courseId);
    }
    final groups = groupController.groupsByCourse[courseId] ?? const [];
    _group = groups.firstWhereOrNull((g) => g.id == groupId);
    if (_group != null) {
      _nameCtrl.text = _group!.name;
      _selectedCategoryId = _group!.categoryId;
    }
    if (mounted) setState(() => _loadingInit = false);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _group == null) return;
    setState(() => _saving = true);
    try {
      final updated = _group!.copyWith(
        name: _nameCtrl.text.trim(),
        categoryId: _selectedCategoryId ?? _group!.categoryId,
      );
      final result = await groupController.updateGroup(updated);
      if (result != null) {
        Get.back();
        Get.snackbar('Grupo actualizado', 'Los cambios se guardaron',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppTheme.successGreen.withOpacity(.15));
      } else {
        Get.snackbar('Error', groupController.errorMessage.value,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.withOpacity(.15));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingInit) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_group == null) {
      return const Scaffold(body: Center(child: Text('Grupo no encontrado')));
    }

    final categories =
        categoryController.categoriesByCourse[courseId] ?? const [];

    return CoursePageScaffold(
      header: const CourseHeader(
        title: 'Editar',
        subtitle: 'Grupo',
        showEdit: false,
      ),
      sections: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Ingresa un nombre' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                isExpanded: true, 
                items: categories
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(
                            c.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _selectedCategoryId = val),
                decoration: const InputDecoration(labelText: 'Categoría'),
              ),
              const SizedBox(height: 24),
              Obx(() {
                final loading = groupController.isLoading.value || _saving;
                return SaveButton(onPressed: _save, loading: loading);
              }),
            ],
          ),
        ),
      ],
    );
  }
}
