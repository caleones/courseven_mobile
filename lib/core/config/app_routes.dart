import 'package:get/get.dart';
import '../../presentation/pages/auth/login_page.dart';
import '../../presentation/pages/auth/email_verification_page.dart';
import '../../presentation/pages/home/home_page.dart';

// todas las rutas de navegación de la app
class AppRoutes {
  static const String login = '/login';
  static const String emailVerification = '/email-verification';
  static const String home = '/home';

  static List<GetPage> routes = [
    GetPage(name: login, page: () => const LoginPage()),
    GetPage(name: emailVerification, page: () => const EmailVerificationPage()),
    GetPage(name: home, page: () => const HomePage()),
  ];
}
