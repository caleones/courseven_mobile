import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/starry_background.dart';
import '../../../widgets/common/theme_toggle_widget.dart';
import '../login_page.dart';

class PasswordResetSuccessPage extends StatelessWidget {
  const PasswordResetSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StarryBackground(
        isDarkMode: Theme.of(context).brightness == Brightness.dark,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
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

                const SizedBox(height: 24),

                
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle,
                            size: 100,
                            color: Colors.green,
                          ),
                        ),

                        const SizedBox(height: 24),

                        
                        Text(
                          '¡Contraseña cambiada!',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 12),

                        
                        Text(
                          'Tu contraseña ha sido actualizada exitosamente. Ya puedes iniciar sesión con tu nueva contraseña.',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    height: 1.5,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color
                                        ?.withOpacity(0.8),
                                  ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 32),

                        
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () =>
                                Get.offAll(() => const LoginPage()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.goldAccent,
                              foregroundColor: AppTheme.premiumBlack,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: const Text(
                              'Iniciar Sesión',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.goldAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.goldAccent.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.security,
                                color: AppTheme.goldAccent,
                                size: 24,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Consejo de seguridad',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Por tu seguridad, asegúrate de mantener tu contraseña privada y no compartirla con nadie.',
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
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
