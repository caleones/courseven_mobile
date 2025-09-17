import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/theme_toggle_widget.dart';
import '../../widgets/common/starry_background.dart';
import '../../../core/config/app_routes.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  // Controllers
  final AuthController authController = Get.find<AuthController>();
  final ThemeController themeController = Get.find<ThemeController>();

  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  // Form Controllers
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _forgotEmailController = TextEditingController();

  // UI State
  bool _isLoginMode = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _keepLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
  }

  void _startAnimations() {
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _slideController.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      _scaleController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _forgotEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<ThemeController>(
        builder: (themeController) {
          return StarryBackground(
            isDarkMode: themeController.isDarkMode,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Header con toggle de tema
                    _buildHeader(),

                    const SizedBox(height: 40),

                    // Logo y título
                    _buildLogo(),

                    const SizedBox(height: 40),

                    // Formulario
                    _buildForm(),

                    const SizedBox(height: 30),

                    // Botones de acción
                    _buildActionButtons(),

                    const SizedBox(height: 20),

                    // Opciones adicionales
                    _buildAdditionalOptions(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ThemeToggleWidget(),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Column(
          children: [
            Image.asset(
              'assets/images/courseven_logo.png',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            Text(
              _isLoginMode ? 'Ingresar' : 'Regístrate',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _isLoginMode
                  ? 'Accede a tu cuenta de CourSEVEN'
                  : 'Únete a la comunidad estudiantil',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.color
                        ?.withOpacity(0.7),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Email o Username en login; Email en registro
            CustomTextField(
              controller: _emailController,
              labelText: _isLoginMode ? 'Email o nombre de usuario' : 'Email',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return _isLoginMode
                      ? 'Ingresa tu email o nombre de usuario'
                      : 'Por favor ingresa tu email';
                }
                if (!_isLoginMode && !GetUtils.isEmail(value)) {
                  return 'Por favor ingresa un email válido';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Campos adicionales para registro
            if (!_isLoginMode) ...[
              // Campo Username
              CustomTextField(
                controller: _usernameController,
                labelText: 'Nombre de usuario',
                prefixIcon: Icons.alternate_email,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa tu nombre de usuario';
                  }
                  if (value.length < 3) {
                    return 'El nombre de usuario debe tener al menos 3 caracteres';
                  }
                  if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                    return 'Solo letras, números y guiones bajos';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _firstNameController,
                      labelText: 'Nombre',
                      prefixIcon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa tu nombre';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      controller: _lastNameController,
                      labelText: 'Apellido',
                      prefixIcon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa tu apellido';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Contraseña
            CustomTextField(
              controller: _passwordController,
              labelText: 'Contraseña',
              prefixIcon: Icons.lock_outline,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xFFFFD700),
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa tu contraseña';
                }
                if (!_isLoginMode && value.length < 6) {
                  return 'La contraseña debe tener al menos 6 caracteres';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Confirmar contraseña (solo en registro)
            if (!_isLoginMode)
              CustomTextField(
                controller: _confirmPasswordController,
                labelText: 'Confirmar Contraseña',
                prefixIcon: Icons.lock_outline,
                obscureText: _obscureConfirmPassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: const Color(0xFFFFD700),
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
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

            // Mantener sesión iniciada (solo en login)
            if (_isLoginMode) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(
                    value: _keepLoggedIn,
                    onChanged: (value) {
                      setState(() {
                        _keepLoggedIn = value ?? false;
                      });
                    },
                    activeColor: const Color(0xFFFFD700),
                    checkColor: Colors.black,
                  ),
                  Expanded(
                    child: Text(
                      'Mantener sesión iniciada',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          // Botón principal
          Obx(() => CustomButton(
                text: _isLoginMode ? 'Ingresar' : 'Regístrate',
                onPressed: _handleSubmit,
                isLoading: authController.isLoading,
              )),

          const SizedBox(height: 16),

          // Alternar entre login y registro
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isLoginMode ? '¿No tienes cuenta?' : '¿Ya tienes cuenta?',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLoginMode = !_isLoginMode;
                  });
                  _formKey.currentState?.reset();
                },
                child: Text(
                  _isLoginMode ? 'Regístrate' : 'Ingresar',
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalOptions() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          // Olvidé mi contraseña
          if (_isLoginMode)
            TextButton(
              onPressed: _showForgotPasswordDialog,
              child: Text(
                '¿Olvidaste tu contraseña?',
                style: TextStyle(
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withOpacity(0.7),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    bool success;

    if (_isLoginMode) {
      success = await authController.login(
        identifier: _emailController.text.trim(),
        password: _passwordController.text,
        keepLoggedIn: _keepLoggedIn,
      );

      // Solo navegar a Home si es login exitoso
      if (success) {
        Get.offAllNamed(AppRoutes.home);
      }
    } else {
      success = await authController.register(
        email: _emailController.text.trim(),
        username: _usernameController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        password: _passwordController.text,
      );

      // Para registro, no navegar aquí - el AuthController manejará la navegación
      // El registro exitoso lleva a email verification, no a Home directamente
    }
  }

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recuperar Contraseña'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Ingresa tu email para recibir instrucciones de recuperación.'),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _forgotEmailController,
              labelText: 'Email',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          Obx(() => CustomButton(
                text: 'Enviar',
                onPressed: () async {
                  if (_forgotEmailController.text.isEmail) {
                    final success = await authController.forgotPassword(
                      email: _forgotEmailController.text.trim(),
                    );
                    if (success) {
                      Get.back();
                      _forgotEmailController.clear();
                    }
                  } else {
                    Get.snackbar(
                      'Error',
                      'Por favor ingresa un email válido',
                      backgroundColor: Colors.red[400],
                      colorText: Colors.white,
                    );
                  }
                },
                isLoading: authController.isLoading,
              )),
        ],
      ),
    );
  }
}
