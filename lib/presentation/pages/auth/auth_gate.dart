import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../auth/login_page.dart';
import '../home/home_page.dart';

// decide si mostrar login o ir directo al home
// depende de si el usuario ya tiene sesión guardada
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();

    return Obx(
      () {
        print(
            'AuthGate build - isInitialized: ${authController.isInitialized}, isLoggedIn: ${authController.isLoggedIn}');

        // mientras reviso si hay sesión muestro loading
        if (!authController.isInitialized) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // logo de la app
                  Image.asset(
                    'assets/images/courseven_logo.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 30),

                  // indicador de carga
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // texto de carga
                  Text(
                    'Cargando...',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          );
        }

        // si ya está logueado voy al home
        if (authController.isLoggedIn) {
          print('Navegando a HomePage');
          return const HomePage();
        }

        // si no está logueado muestro el login
        print('Mostrando LoginPage');
        return const LoginPage();
      },
    );
  }
}
