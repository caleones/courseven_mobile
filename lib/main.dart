import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'core/di/dependency_injection.dart';
import 'core/config/app_routes.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/pages/auth/auth_gate.dart';
import 'package:courseven/presentation/controllers/theme_controller.dart';
import 'presentation/widgets/common/starry_background.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('[INIT] Iniciando aplicación CourSEVEN');

  // Configuras las dependencias necesarias para el funcionamiento de la app
  debugPrint('[DEPENDENCIES] Iniciando configuración de dependencias');
  // Cargas las variables de entorno desde el archivo .env
  try {
    debugPrint('[ENV] Cargando variables de entorno');
    await dotenv.load(fileName: '.env');
    debugPrint('[ENV] Variables de entorno configuradas correctamente');
    if (kDebugMode) {
      debugPrint('[ENV] ROBLE_DB_NAME: ${dotenv.maybeGet('ROBLE_DB_NAME')}');
      debugPrint(
          '[ENV] ROBLE_READONLY_EMAIL: ${dotenv.maybeGet('ROBLE_READONLY_EMAIL')}');
      debugPrint(
          '[ENV] ROBLE_READONLY_PASSWORD configurado: ${dotenv.maybeGet('ROBLE_READONLY_PASSWORD') != null}');
    }
  } catch (e) {
    debugPrint('[ENV] Error al cargar variables de entorno: $e');
  }
  await DependencyInjection.init();
  debugPrint('[DEPENDENCIES] Dependencias configuradas exitosamente');

  // Inicializas el controlador de tema para manejar modo claro/oscuro
  debugPrint('[THEME] Configurando controlador de tema');
  Get.put(ThemeController());
  debugPrint('[THEME] Controlador de tema configurado');

  debugPrint('[INIT] Lanzando aplicación');
  runApp(const CourSEVENApp());
}

class CourSEVENApp extends StatelessWidget {
  const CourSEVENApp({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('[UI] Construyendo widget principal de la aplicación');
    return GetBuilder<ThemeController>(
      builder: (themeController) {
        debugPrint('[UI] Aplicando configuración de tema');
        return GetMaterialApp(
          title: 'CourSEVEN',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeController.themeMode,
          home: const AuthGate(),
          getPages: AppRoutes.routes,
          builder: (context, child) {
            // Aplica el fondo estelar a todas las pantallas
            return GetBuilder<ThemeController>(
              builder: (tc) => StarryBackground(
                isDarkMode: tc.isDarkMode,
                child: child ?? const SizedBox.shrink(),
              ),
            );
          },
        );
      },
    );
  }
}
