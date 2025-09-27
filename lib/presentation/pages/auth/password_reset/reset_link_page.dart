import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/theme_controller.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/theme_toggle_widget.dart';
import '../../../widgets/common/starry_background.dart';
import '../../../widgets/common/password_requirements.dart';
import 'password_reset_success_page.dart';

class ResetLinkPage extends StatefulWidget {
  const ResetLinkPage({super.key});

  @override
  State<ResetLinkPage> createState() => _ResetLinkPageState();
}

class _ResetLinkPageState extends State<ResetLinkPage> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authController = Get.find<AuthController>();
  final ThemeController themeController = Get.find<ThemeController>();

  
  static const int _tokenTotalSeconds = 15 * 60; 
  static const int _resendCooldownSeconds = 60; 
  int _tokenSecondsRemaining = _tokenTotalSeconds;
  int _resendSecondsRemaining = _resendCooldownSeconds;
  Timer? _timer;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _startTimers();
  }

  void _startTimers() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_tokenSecondsRemaining > 0) {
          _tokenSecondsRemaining--;
        }
        if (_resendSecondsRemaining > 0) {
          _resendSecondsRemaining--;
        }
      });
    });
  }

  double get _tokenProgress =>
      _tokenTotalSeconds == 0 ? 0 : _tokenSecondsRemaining / _tokenTotalSeconds;

  bool get _canResend => _resendSecondsRemaining <= 0;

  String _formatMmSs(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _urlController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submitReset() async {
    if (!_formKey.currentState!.validate()) return;

    final url = _urlController.text.trim();
    final token = _authController.extractTokenFromUrl(url);
    if (token == null) {
      Get.snackbar(
        'Error',
        'La URL proporcionada no es válida. Asegúrate de copiar el enlace completo del correo.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final newPassword = _passwordController.text.trim();
    final success = await _authController.resetPassword(token, newPassword);
    if (success) {
      Get.offAll(() => const PasswordResetSuccessPage());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<ThemeController>(
        builder: (themeController) => Stack(
          children: [
            
            StarryBackground(
              child: Container(),
              isDarkMode: themeController.isDarkMode,
            ),

            
            SafeArea(
              child: Column(
                children: [
                  
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios,
                            color: themeController.isDarkMode
                                ? AppTheme.premiumWhite
                                : AppTheme.premiumBlack,
                          ),
                          onPressed: () => Get.back(),
                        ),
                        const Spacer(),
                        const ThemeToggleWidget(),
                      ],
                    ),
                  ),

                  
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 20),

                            
                            Icon(
                              Icons.link,
                              size: 80,
                              color: AppTheme.goldAccent,
                            ),

                            const SizedBox(height: 32),

                            
                            Text(
                              'Pega tu enlace de recuperación',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 16),

                            
                            Text(
                              'Ve al correo que recibiste de ROBLE, busca el botón "Restablecer Contraseña", mantén presionado sobre él y selecciona "Copiar enlace". Luego pega aquí la URL completa.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    height: 1.5,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color
                                        ?.withOpacity(0.8),
                                  ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 16),

                            
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surface
                                    .withOpacity(0.6),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.goldAccent.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.timer_outlined,
                                          color: AppTheme.goldAccent, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Tiempo restante: ${_formatMmSs(_tokenSecondsRemaining)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: _tokenProgress,
                                      minHeight: 8,
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.15),
                                      color: AppTheme.goldAccent,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.goldAccent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '📧 Pasos a seguir:',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '1. Abre el correo de ROBLE en tu bandeja\n'
                                    '2. Busca el botón "Restablecer Contraseña"\n'
                                    '3. Mantén presionado sobre el botón\n'
                                    '4. Selecciona "Copiar enlace" del menú\n'
                                    '5. Pega aquí la URL completa',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.color
                                              ?.withOpacity(0.8),
                                        ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 32),

                            
                            TextFormField(
                              controller: _urlController,
                              keyboardType: TextInputType.url,
                              maxLines: 3,
                              decoration: InputDecoration(
                                labelText: 'Enlace de recuperación',
                                hintText:
                                    'https://roble.openlab.uninorte.edu.co/reset-password?token=...',
                                prefixIcon: Icon(Icons.link,
                                    color: AppTheme.goldAccent),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Por favor ingresa el enlace de recuperación';
                                }

                                if (!value.contains(
                                        'roble.openlab.uninorte.edu.co') ||
                                    !value.contains('token=')) {
                                  return 'El enlace no parece ser válido. Debe ser de ROBLE y contener un token';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 24),

                            
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscureNewPassword,
                              decoration: InputDecoration(
                                labelText: 'Nueva contraseña',
                                hintText: 'Ingresa tu nueva contraseña',
                                prefixIcon: Icon(Icons.lock_outline,
                                    color: AppTheme.goldAccent),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureNewPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: AppTheme.goldAccent,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureNewPassword =
                                          !_obscureNewPassword;
                                    });
                                  },
                                ),
                              ),
                              onChanged: (_) => setState(() {}),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingresa una contraseña';
                                }
                                if (value.length < 8) {
                                  return 'La contraseña debe tener al menos 8 caracteres';
                                }
                                if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)')
                                    .hasMatch(value)) {
                                  return 'Debe contener mayúscula, minúscula y número';
                                }
                                return null;
                              },
                            ),

                            
                            PasswordRequirements(
                              password: _passwordController.text,
                              padding: const EdgeInsets.only(top: 8),
                            ),

                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              decoration: InputDecoration(
                                labelText: 'Confirmar contraseña',
                                hintText: 'Confirma tu nueva contraseña',
                                prefixIcon: Icon(Icons.lock_outline,
                                    color: AppTheme.goldAccent),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: AppTheme.goldAccent,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword =
                                          !_obscureConfirmPassword;
                                    });
                                  },
                                ),
                              ),
                              onChanged: (_) => setState(() {}),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor confirma tu contraseña';
                                }
                                if (value != _passwordController.text) {
                                  return 'Las contraseñas no coinciden';
                                }
                                return null;
                              },
                            ),

                            
                            if (_confirmPasswordController.text.isNotEmpty &&
                                _confirmPasswordController.text !=
                                    _passwordController.text)
                              Padding(
                                padding: const EdgeInsets.only(top: 6.0),
                                child: Row(
                                  children: const [
                                    Icon(Icons.error_outline,
                                        size: 16, color: Colors.redAccent),
                                    SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Las contraseñas no coinciden',
                                        style: TextStyle(
                                          color: Colors.redAccent,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            const SizedBox(height: 16),

                            
                            Obx(() {
                              if (_authController.errorMessage.isNotEmpty) {
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border:
                                        Border.all(color: Colors.red.shade300),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline,
                                          color: Colors.red),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _authController.errorMessage,
                                          style: const TextStyle(
                                              color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            }),

                            
                            Obx(() => ElevatedButton(
                                  onPressed: _authController.isLoading
                                      ? null
                                      : _submitReset,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.goldAccent,
                                    foregroundColor: AppTheme.premiumBlack,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: _authController.isLoading
                                      ? SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            color: AppTheme.premiumBlack,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          'Actualizar Contraseña',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                )),

                            const SizedBox(height: 24),

                            
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.goldAccent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: AppTheme.goldAccent,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '¿No encuentras el correo?',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Revisa tu carpeta de spam o correo no deseado. El correo puede tardar unos minutos en llegar.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.color
                                              ?.withOpacity(0.8),
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  Column(
                                    children: [
                                      TextButton(
                                        onPressed: _canResend
                                            ? () => Get.back()
                                            : null,
                                        child: Text(
                                          _canResend
                                              ? 'Solicitar nuevo enlace'
                                              : 'Solicitar nuevo enlace (${_formatMmSs(_resendSecondsRemaining)})',
                                          style: TextStyle(
                                            color: _canResend
                                                ? AppTheme.goldAccent
                                                : Theme.of(context)
                                                    .disabledColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      if (!_canResend)
                                        Text(
                                          'Disponible en ${_formatMmSs(_resendSecondsRemaining)}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.color
                                                    ?.withOpacity(0.7),
                                              ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
