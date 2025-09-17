import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../data/services/roble_service.dart';
import '../../presentation/controllers/auth_controller.dart';
import '../../presentation/controllers/theme_controller.dart';

// configuro todas las dependencias de la app al inicio
class DependencyInjection {
  // método principal que llamo en main.dart
  static Future<void> init() async {
    // configuro el cliente HTTP
    _setupHttpClient();

    // configuro los servicios
    _setupServices();

    // configuro los controladores
    _setupControllers();
  }

  // configuro Dio para las peticiones HTTP
  static void _setupHttpClient() {
    final dio = Dio();

    // timeouts para que no se cuelgue
    dio.options.connectTimeout = const Duration(seconds: 30);
    dio.options.receiveTimeout = const Duration(seconds: 30);
    dio.options.sendTimeout = const Duration(seconds: 30);

    // headers que siempre mando
    dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // en desarrollo muestro los logs de las peticiones
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: true,
          responseHeader: false,
          error: true,
        ),
      );
    }

    // registro Dio como singleton para usarlo en toda la app
    Get.put<Dio>(dio, permanent: true);
  }

  // configuro los servicios que manejo
  static void _setupServices() {
    // servicio principal para comunicarme con ROBLE
    Get.put<RobleService>(
      RobleService(),
      permanent: true,
    );
  }

  // configuro los controladores principales
  static void _setupControllers() {
    // controlador de tema (lo inicio primero)
    Get.put<ThemeController>(
      ThemeController(),
      permanent: true,
    );

    // controlador de autenticación
    Get.put<AuthController>(
      AuthController(Get.find<RobleService>()),
      permanent: true,
    );
  }

  // limpio todas las dependencias cuando cierro la app
  static void dispose() {
    Get.deleteAll();
  }
}
