import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/category_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/course/course_ui_components.dart';

class CategoryEditPage extends StatefulWidget {
  const CategoryEditPage({super.key});

  @override
  State<CategoryEditPage> createState() => _CategoryEditPageState();
}

class _CategoryEditPageState extends State<CategoryEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _maxMembersCtrl = TextEditingController();
  late final CategoryController categoryController;
  late final String courseId;
  late final String categoryId;
  String _groupingMethod = 'manual';

  @override
  void initState() {
    super.initState();
    categoryController = Get.find<CategoryController>();
    final args = Get.arguments as Map<String, dynamic>?;
    courseId = args?['courseId'] ?? '';
    categoryId = args?['categoryId'] ?? '';
    _load();
  }

  Future<void> _load() async {
    if (courseId.isEmpty || categoryId.isEmpty) return;
    final categories = categoryController.categoriesByCourse[courseId] ?? [];
    final category = categories.firstWhereOrNull((c) => c.id == categoryId);
    if (category != null) {
      _nameCtrl.text = category.name;
      _descCtrl.text = category.description ?? '';
      _groupingMethod = category.groupingMethod;
      _maxMembersCtrl.text = category.maxMembersPerGroup?.toString() ?? '';
      setState(() {});
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
    final categories = categoryController.categoriesByCourse[courseId] ?? [];
    final category = categories.firstWhereOrNull((c) => c.id == categoryId);
    if (category == null) return;

    final maxMembers = _maxMembersCtrl.text.trim().isEmpty
        ? null
        : int.tryParse(_maxMembersCtrl.text.trim());

    final updated = await categoryController.updateCategory(
      category.copyWith(
        name: _nameCtrl.text.trim(),
        description:
            _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        groupingMethod: _groupingMethod,
        maxMembersPerGroup: maxMembers,
      ),
    );
    if (updated != null && mounted) {
      Get.snackbar(
        'Categoría actualizada',
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
      header: const CourseHeader(
        title: 'Editar',
        subtitle: 'Categoría',
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
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Text('Método de agrupación',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Column(
                children: [
                  RadioListTile<String>(
                    title: const Text('Manual'),
                    subtitle: const Text(
                        'Los estudiantes se unen a grupos manualmente'),
                    value: 'manual',
                    groupValue: _groupingMethod,
                    onChanged: (value) =>
                        setState(() => _groupingMethod = value!),
                  ),
                  RadioListTile<String>(
                    title: const Text('Aleatorio'),
                    subtitle:
                        const Text('Los grupos se forman automáticamente'),
                    value: 'random',
                    groupValue: _groupingMethod,
                    onChanged: (value) =>
                        setState(() => _groupingMethod = value!),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _maxMembersCtrl,
                decoration: const InputDecoration(
                  labelText: 'Máximo miembros por grupo (opcional)',
                  hintText: 'Ej: 4',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final num = int.tryParse(v.trim());
                  if (num == null || num < 1)
                    return 'Debe ser un número mayor a 0';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Obx(() {
                final loading = categoryController.isLoading.value;
                return SaveButton(onPressed: _submit, loading: loading);
              }),
            ],
          ),
        ),
      ],
    );
  }
}
