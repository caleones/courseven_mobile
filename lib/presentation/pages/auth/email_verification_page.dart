import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:async';
import '../../controllers/auth_controller.dart';
import '../../widgets/common/starry_background.dart';

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage>
    with TickerProviderStateMixin {
  final AuthController authController = Get.find<AuthController>();

  
  final List<TextEditingController> _codeControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );

  final List<FocusNode> _focusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );

  
  late Timer _timer;
  int _timeRemaining = 300; 
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  bool _isVerifying = false;
  bool _canResend = false;

  
  late final String email;
  late final String password;
  late final String firstName;
  late final String lastName;
  late final String? username;

  @override
  void initState() {
    super.initState();

    
    final Map<String, dynamic> args = Get.arguments ?? {};
    email = args['email'] ?? '';
    password = args['password'] ?? '';
    firstName = args['firstName'] ?? '';
    lastName = args['lastName'] ?? '';
    username = args['username'];

    _initializeAnimations();
    _startTimer();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _fadeController.forward();
    _pulseController.repeat(reverse: true);
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_timeRemaining > 0) {
            _timeRemaining--;
          } else {
            _timer.cancel();
            _showTimeExpiredDialog();
          }

          
          if (_timeRemaining == 270) {
            _canResend = true;
          }
        });
      }
    });
  }

  void _showTimeExpiredDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Tiempo expirado'),
        content: const Text(
            'El código de verificación ha expirado. Debes registrarte nuevamente.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Get.back(); 
              Get.back(); 
            },
            child: const Text('Volver al registro'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _onCodeChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }

    
    if (value.isNotEmpty && index == 5) {
      _verifyCode();
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeControllers.map((controller) => controller.text).join();

    if (code.length != 6) {
      Get.snackbar(
        'Código incompleto',
        'Por favor ingresa los 6 dígitos del código',
        backgroundColor: Colors.orange[400],
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      print('✅ Verificando código: $code');

      final success = await authController.verifyEmailAndComplete(
        email: email,
        code: code,
        password: password,
        firstName: firstName,
        lastName: lastName,
        username: username,
      );

      if (success) {
        
        _timer.cancel();
      } else {
        setState(() {
          _isVerifying = false;
        });

        
        for (var controller in _codeControllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
      }
    } catch (e) {
      setState(() {
        _isVerifying = false;
      });

      
      for (var controller in _codeControllers) {
        controller.clear();
      }
      _focusNodes[0].requestFocus();
    }
  }

  Future<void> _resendCode() async {
    if (!_canResend) return;

    setState(() {
      _canResend = false;
      _timeRemaining = 300; 
    });

    
    for (var controller in _codeControllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus(); 

    try {
      
      await authController.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        username: username,
      );

      Get.snackbar(
        'Código reenviado',
        'Se ha enviado un nuevo código a tu email. Revisa tu bandeja de entrada.',
        backgroundColor: const Color(0xFFFFD700),
        colorText: const Color(0xFF0D0D0D),
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      setState(() {
        _canResend = true;
      });

      Get.snackbar(
        'Error',
        'No se pudo reenviar el código. Inténtalo de nuevo.',
        backgroundColor: Colors.red[400],
        colorText: Colors.white,
      );
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _fadeController.dispose();
    _pulseController.dispose();

    for (var controller in _codeControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StarryBackground(
        isDarkMode: true,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          'Verificar Email',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), 
                    ],
                  ),

                  const SizedBox(height: 40),

                  
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(
                          color: const Color(0xFFFFD700),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.email_outlined,
                        color: Color(0xFFFFD700),
                        size: 40,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  
                  const Text(
                    'Revisa tu correo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Te hemos enviado un código de verificación a:',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    email,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Revisa también tu carpeta de spam',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 48),

                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (index) {
                      return Container(
                        width: 50,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _focusNodes[index].hasFocus
                                ? const Color(0xFFFFD700)
                                : Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        alignment: Alignment.center, 
                        child: TextField(
                          controller: _codeControllers[index],
                          focusNode: _focusNodes[index],
                          textAlign: TextAlign.center,
                          textAlignVertical: TextAlignVertical.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            height: 1.0, 
                          ),
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            counterText: '',
                            contentPadding:
                                EdgeInsets.zero, 
                            isDense: true, 
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (value) => _onCodeChanged(index, value),
                          onTap: () {
                            
                            if (_codeControllers[index].text.isEmpty &&
                                index > 0) {
                              for (int i = 0; i < index; i++) {
                                if (_codeControllers[i].text.isEmpty) {
                                  _focusNodes[i].requestFocus();
                                  return;
                                }
                              }
                            }
                          },
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 32),

                  
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'El código expira en ${_formatTime(_timeRemaining)}',
                      style: TextStyle(
                        color: _timeRemaining < 60
                            ? Colors.red[300]
                            : Colors.white.withOpacity(0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const Spacer(),

                  
                  if (_isVerifying)
                    const Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _verifyCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD700),
                          foregroundColor: const Color(0xFF0D0D0D),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 4,
                        ),
                        child: const Text(
                          'Verificar código',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  
                  TextButton(
                    onPressed: _canResend ? _resendCode : null,
                    child: Text(
                      _canResend
                          ? 'Reenviar código'
                          : 'Reenviar disponible en ${_formatTime(_timeRemaining - 270)}',
                      style: TextStyle(
                        color: _canResend
                            ? const Color(0xFFFFD700)
                            : Colors.white.withOpacity(0.5),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
