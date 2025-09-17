import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/di/dependency_injection.dart';
import 'core/config/app_routes.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/pages/auth/auth_gate.dart';
import 'package:courseven/presentation/controllers/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('Iniciando CourSEVEN...');

  // Initialize dependencies
  print('Inicializando dependencias...');
  await DependencyInjection.init();
  print('Dependencias inicializadas');

  // Initialize theme controller
  print('Inicializando ThemeController...');
  Get.put(ThemeController());
  print('ThemeController inicializado');

  print('Lanzando app...');
  runApp(const CourSEVENApp());
}

class CourSEVENApp extends StatelessWidget {
  const CourSEVENApp({super.key});

  @override
  Widget build(BuildContext context) {
    print('Construyendo CourSEVENApp...');
    return GetBuilder<ThemeController>(
      builder: (themeController) {
        print('ThemeController encontrado, construyendo MaterialApp...');
        return GetMaterialApp(
          title: 'CourSEVEN',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeController.themeMode,
          home: const AuthGate(),
          getPages: AppRoutes.routes,
        );
      },
    );
  }
}
