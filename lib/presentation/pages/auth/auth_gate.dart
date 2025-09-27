import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../auth/login_page.dart';
import '../home/home_page.dart';



class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();

    return Obx(
      () {
        print(
            'AuthGate build - isInitialized: ${authController.isInitialized}, isLoggedIn: ${authController.isLoggedIn}');

        
        if (!authController.isInitialized) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  
                  Image.asset(
                    'assets/images/courseven_logo.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 30),

                  
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),

                  
                  Text(
                    'Cargando...',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          );
        }

        
        if (authController.isLoggedIn) {
          print('Navegando a HomePage');
          return const HomePage();
        }

        
        print('Mostrando LoginPage');
        return const LoginPage();
      },
    );
  }
}
