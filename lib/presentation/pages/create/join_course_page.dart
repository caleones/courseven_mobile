import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/enrollment_controller.dart';
import '../../theme/app_theme.dart';
import '../../../core/config/app_routes.dart';

class JoinCoursePage extends StatefulWidget {
  const JoinCoursePage({super.key});

  @override
  State<JoinCoursePage> createState() => _JoinCoursePageState();
}

class _JoinCoursePageState extends State<JoinCoursePage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final EnrollmentController controller = Get.find<EnrollmentController>();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unirme a un curso'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ingresa el código de ingreso (join code) proporcionado por tu profesor.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'Código de ingreso',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final val = v?.trim() ?? '';
                    if (val.isEmpty) return 'Ingresa el código';
                    if (val.length < 4) return 'El código es muy corto';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Obx(() {
                  final loading = controller.isLoading.value;
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: loading
                          ? null
                          : () async {
                              if (!_formKey.currentState!.validate()) return;
                              final code = _codeController.text.trim();
                              final res = await controller.joinByCode(code);
                              if (res != null) {
                                
                                Get.snackbar(
                                  '¡Te uniste al curso!',
                                  'Inscripción creada correctamente',
                                  backgroundColor: AppTheme.goldAccent,
                                  colorText: AppTheme.premiumBlack,
                                  duration: const Duration(seconds: 2),
                                );
                                
                                
                                Future.delayed(
                                    const Duration(milliseconds: 300), () {
                                  Get.offAllNamed(AppRoutes.home);
                                });
                              } else if (controller.errorMessage.isNotEmpty) {
                                Get.snackbar('No se pudo unir',
                                    controller.errorMessage.value);
                              }
                            },
                      icon: const Icon(Icons.login),
                      label: Text(loading ? 'Uniendo...' : 'Unirme al curso'),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
