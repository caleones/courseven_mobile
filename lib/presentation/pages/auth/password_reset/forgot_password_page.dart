import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/theme_controller.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/custom_button.dart';
import '../../../widgets/common/custom_text_field.dart';
import '../../../widgets/common/theme_toggle_widget.dart';
import '../../../widgets/common/starry_background.dart';
import 'reset_link_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _authController = Get.find<AuthController>();
  final ThemeController themeController = Get.find<ThemeController>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _authController.requestPasswordReset(_emailController.text.trim());

      if (mounted) {
        
        Get.to(() => const ResetLinkPage());
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Error',
          'Error enviando enlace: $e',
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
          snackPosition: SnackPosition.TOP,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<ThemeController>(
        builder: (themeController) => StarryBackground(
          isDarkMode: themeController.isDarkMode,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    
                    Row(
                      children: const [
                        _BackButtonGold(),
                        Spacer(),
                        ThemeToggleWidget(),
                      ],
                    ),

                    const SizedBox(height: 32),

                    
                    Icon(
                      Icons.lock_reset,
                      size: 80,
                      color: AppTheme.goldAccent,
                    ),

                    const SizedBox(height: 32),

                    
                    Text(
                      '¿Olvidaste tu contraseña?',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),

                    
                    Text(
                      'Ingresa tu correo electrónico y te enviaremos un enlace para restablecer tu contraseña.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.color
                                ?.withOpacity(0.7),
                            height: 1.5,
                          ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 32),

                    
                    CustomTextField(
                      controller: _emailController,
                      labelText: 'Correo electrónico',
                      hintText: 'usuario@correo.com',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa tu correo electrónico';
                        }
                        if (!GetUtils.isEmail(value)) {
                          return 'Por favor ingresa un correo válido';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    
                    CustomButton(
                      text: 'Enviar Enlace',
                      onPressed: _isLoading ? null : _sendResetLink,
                      isLoading: _isLoading,
                    ),

                    const SizedBox(height: 16),

                    
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color:
                                Theme.of(context).dividerColor.withOpacity(0.3),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'o',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color
                                      ?.withOpacity(0.6),
                                ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color:
                                Theme.of(context).dividerColor.withOpacity(0.3),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    
                    OutlinedButton(
                      onPressed: () => Get.to(() => const ResetLinkPage()),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.goldAccent),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Ya tengo un enlace de recuperación',
                        style: TextStyle(
                          color: AppTheme.goldAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text(
                        'Volver al inicio de sesión',
                        style: TextStyle(
                          color: AppTheme.goldAccent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BackButtonGold extends StatelessWidget {
  const _BackButtonGold();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios, color: AppTheme.goldAccent),
      onPressed: () => Get.back(),
      tooltip: 'Atrás',
    );
  }
}
