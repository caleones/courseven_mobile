import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/theme_toggle_widget.dart';
import '../../widgets/common/password_requirements.dart';
import '../../../core/config/app_routes.dart';
import 'password_reset/forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  
  final AuthController authController = Get.find<AuthController>();
  final ThemeController themeController = Get.find<ThemeController>();

  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;

  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  
  bool _isLoginMode = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _keepLoggedIn = false;
  
  
  String _emailAvailabilityMessage = '';
  String _usernameAvailabilityMessage = '';
  AvailabilityStatus _emailStatus = AvailabilityStatus.ok;
  AvailabilityStatus _usernameStatus = AvailabilityStatus.ok;
  DateTime _lastEmailChange = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastUsernameChange = DateTime.fromMillisecondsSinceEpoch(0);
  

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

  Future<void> _debouncedCheckEmailAvailability(String email) async {
    if (_isLoginMode || email.isEmpty || !GetUtils.isEmail(email)) {
      setState(() {
        _emailAvailabilityMessage = '';
      });
      return;
    }
    
    setState(() {
      _emailStatus = AvailabilityStatus.pending;
      _emailAvailabilityMessage = 'Verificando...';
    });
    _lastEmailChange = DateTime.now();
    final scheduledAt = _lastEmailChange;
    await Future.delayed(const Duration(milliseconds: 500));
    if (scheduledAt != _lastEmailChange) return; 

    final available = await authController.checkEmailAvailable(email);
    if (!mounted) return;
    setState(() {
      if (available == true) {
        _emailStatus = AvailabilityStatus.ok;
        _emailAvailabilityMessage = 'Correo disponible';
      } else {
        _emailStatus = AvailabilityStatus.error;
        _emailAvailabilityMessage = 'Ese correo ya está en uso';
      }
    });
  }

  Future<void> _debouncedCheckUsernameAvailability(String username) async {
    final candidate = username.trim();
    
    if (_isLoginMode ||
        candidate.isEmpty ||
        candidate.length < 3 ||
        !RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(candidate)) {
      setState(() {
        _usernameAvailabilityMessage = '';
      });
      return;
    }

    
    setState(() {
      _usernameStatus = AvailabilityStatus.pending;
      _usernameAvailabilityMessage = 'Verificando...';
    });

    _lastUsernameChange = DateTime.now();
    final scheduledAt = _lastUsernameChange;
    await Future.delayed(const Duration(milliseconds: 500));
    if (scheduledAt != _lastUsernameChange) return;

    final available = await authController.checkUsernameAvailable(candidate);
    if (!mounted) return;
    setState(() {
      if (available == true) {
        _usernameStatus = AvailabilityStatus.ok;
        _usernameAvailabilityMessage = 'Nombre de usuario disponible';
      } else {
        _usernameStatus = AvailabilityStatus.error;
        _usernameAvailabilityMessage = 'Ese nombre de usuario ya está en uso';
      }
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              
              _buildHeader(),

              const SizedBox(height: 40),

              
              _buildLogo(),

              const SizedBox(height: 40),

              
              _buildForm(),

              const SizedBox(height: 30),

              
              _buildActionButtons(),

              const SizedBox(height: 20),

              
              _buildAdditionalOptions(),
            ],
          ),
        ),
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
            
            CustomTextField(
              controller: _emailController,
              labelText: _isLoginMode ? 'Email o nombre de usuario' : 'Email',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              onChanged: (v) => _debouncedCheckEmailAvailability(v),
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
            if (!_isLoginMode && _emailAvailabilityMessage.isNotEmpty)
              AvailabilityHint(
                text: _emailAvailabilityMessage,
                status: _emailStatus,
              ),

            const SizedBox(height: 16),

            
            if (!_isLoginMode) ...[
              
              CustomTextField(
                controller: _usernameController,
                labelText: 'Nombre de usuario',
                prefixIcon: Icons.alternate_email,
                onChanged: (v) => _debouncedCheckUsernameAvailability(v),
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
              if (_usernameAvailabilityMessage.isNotEmpty)
                AvailabilityHint(
                  text: _usernameAvailabilityMessage,
                  status: _usernameStatus,
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

            
            CustomTextField(
              controller: _passwordController,
              labelText: 'Contraseña',
              prefixIcon: Icons.lock_outline,
              obscureText: _obscurePassword,
              onChanged: (_) => setState(() {}),
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
                
                if (!_isLoginMode) {
                  if (value.length < 8) return 'Mínimo 8 caracteres';
                  if (!RegExp(r'[A-Z]').hasMatch(value))
                    return 'Incluye una mayúscula';
                  if (!RegExp(r'[a-z]').hasMatch(value))
                    return 'Incluye una minúscula';
                  if (!RegExp(r'\d').hasMatch(value))
                    return 'Incluye un número';
                  if (!RegExp(r'[^A-Za-z0-9]').hasMatch(value))
                    return 'Incluye un símbolo';
                }
                return null;
              },
            ),
            if (!_isLoginMode)
              PasswordRequirements(password: _passwordController.text),

            const SizedBox(height: 16),

            
            if (!_isLoginMode)
              CustomTextField(
                controller: _confirmPasswordController,
                labelText: 'Confirmar Contraseña',
                prefixIcon: Icons.lock_outline,
                obscureText: _obscureConfirmPassword,
                onChanged: (_) => setState(() {}),
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
            if (!_isLoginMode &&
                _confirmPasswordController.text.isNotEmpty &&
                _confirmPasswordController.text != _passwordController.text)
              const AvailabilityHint(
                text: 'Las contraseñas no coinciden',
                status: AvailabilityStatus.error,
              ),

            
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
          
          Obx(() => CustomButton(
                text: _isLoginMode ? 'Ingresar' : 'Regístrate',
                onPressed: _handleSubmit,
                isLoading: authController.isLoading,
              )),

          const SizedBox(height: 16),

          
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
          
          if (_isLoginMode)
            TextButton(
              onPressed: () => Get.to(() => const ForgotPasswordPage()),
              child: Text(
                '¿Olvidaste tu contraseña?',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withOpacity(0.9)
                      : Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withOpacity(0.8),
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

      
      if (success) {
        Get.offAllNamed(AppRoutes.home);
      }
    } else {
      
      final email = _emailController.text.trim();
      final username = _usernameController.text.trim();
      final emailOk = await authController.checkEmailAvailable(email);
      final usernameOk = await authController.checkUsernameAvailable(username);
      if (!emailOk || !usernameOk) {
        setState(() {
          if (emailOk == true) {
            _emailStatus = AvailabilityStatus.ok;
            _emailAvailabilityMessage = 'Correo disponible';
          } else {
            _emailStatus = AvailabilityStatus.error;
            _emailAvailabilityMessage = 'Ese correo ya está en uso';
          }

          if (usernameOk == true) {
            _usernameStatus = AvailabilityStatus.ok;
            _usernameAvailabilityMessage = 'Nombre de usuario disponible';
          } else {
            _usernameStatus = AvailabilityStatus.error;
            _usernameAvailabilityMessage =
                'Ese nombre de usuario ya está en uso';
          }
        });
        Get.snackbar(
          'Validación',
          emailOk == false
              ? 'El correo ya está registrado'
              : usernameOk == false
                  ? 'El nombre de usuario ya está en uso'
                  : 'Valores no disponibles',
          backgroundColor: Colors.red[400],
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
        return;
      }

      success = await authController.register(
        email: _emailController.text.trim(),
        username: _usernameController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        password: _passwordController.text,
      );

      
      
    }
  }
}

class AvailabilityHint extends StatelessWidget {
  final String text;
  final AvailabilityStatus status;
  const AvailabilityHint({super.key, required this.text, required this.status});

  @override
  Widget build(BuildContext context) {
    final Color color = switch (status) {
      AvailabilityStatus.ok => Colors.green,
      AvailabilityStatus.error => Colors.redAccent,
      AvailabilityStatus.pending =>
        Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.8) ??
            Colors.grey,
    };
    return Padding(
      padding: const EdgeInsets.only(top: 6.0),
      child: Row(
        children: [
          if (status == AvailabilityStatus.pending)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: color,
              ),
            )
          else
            Icon(
              status == AvailabilityStatus.ok
                  ? Icons.check_circle
                  : Icons.error_outline,
              size: 16,
              color: color,
            ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

enum AvailabilityStatus { ok, error, pending }
