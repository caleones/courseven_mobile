import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/services/roble_service.dart';
import '../../domain/models/user.dart';
import '../../core/config/app_routes.dart';
import '../pages/auth/login_page.dart';

class AuthController extends GetxController {
  final RobleService _authService;
  static const _secureStorage = FlutterSecureStorage();

  
  final _isLoggedIn = false.obs;
  final _isLoading = false.obs;
  final _isInitialized = false
      .obs; 
  final _currentUser = Rxn<User>();
  final _errorMessage = ''.obs;
  final _selectedDatabase = 'uninorte'.obs; 

  
  Timer? _tokenRefreshTimer;

  
  bool get isLoggedIn => _isLoggedIn.value;
  bool get isLoading => _isLoading.value;
  bool get isInitialized => _isInitialized.value;
  User? get currentUser => _currentUser.value;
  String get errorMessage => _errorMessage.value;
  String get selectedDatabase => _selectedDatabase.value;

  
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _databaseKey = 'selected_database';

  AuthController(this._authService);

  @override
  void onInit() {
    super.onInit();
    _loadStoredSession();
  }

  
  Future<void> _loadStoredSession() async {
    try {
      debugPrint('[AUTH_CONTROLLER] Iniciando carga de sesión almacenada');

      final accessToken = await _secureStorage.read(key: _accessTokenKey);
      final storedDatabase = await _secureStorage.read(key: _databaseKey);
      final keepLoggedInStr = await _secureStorage.read(key: 'keep_logged_in');
      final keepLoggedIn = keepLoggedInStr == 'true';

      if (kDebugMode) {
        debugPrint(
            '[AUTH_CONTROLLER] Datos encontrados - Token: ${accessToken != null}, Database: ${storedDatabase != null}, KeepLoggedIn: $keepLoggedIn');
      }

      if (accessToken != null && storedDatabase != null && keepLoggedIn) {
        debugPrint('[AUTH_CONTROLLER] Restaurando sesión persistente');
        _selectedDatabase.value = storedDatabase;

        try {
          
          final tokenCheck =
              await _authService.verifyToken(accessToken: accessToken);
          final valid =
              tokenCheck['valid'] == true || tokenCheck['success'] == true;
          if (valid) {
            final storedEmail = await _secureStorage.read(key: 'user_email');
            if (storedEmail != null && storedEmail.isNotEmpty) {
              
              final dbUser = await _authService.getUserFromDatabase(
                accessToken: accessToken,
                email: storedEmail,
              );
              if (dbUser != null) {
                
                final user = User(
                  id: dbUser['_id']?.toString() ?? '',
                  studentId: dbUser['student_id']?.toString() ?? '',
                  email: dbUser['email']?.toString() ?? storedEmail,
                  firstName: dbUser['first_name']?.toString() ?? '',
                  lastName: dbUser['last_name']?.toString() ?? '',
                  username: dbUser['username']?.toString() ?? '',
                  createdAt: dbUser['created_at'] != null
                      ? DateTime.parse(dbUser['created_at'].toString())
                      : DateTime.now(),
                );
                _currentUser.value = user;
                _isLoggedIn.value = true;

                
                _startTokenRefreshTimer();

                debugPrint(
                    '[AUTH_CONTROLLER] Sesión restaurada exitosamente desde DB');
              } else {
                debugPrint(
                    '[AUTH_CONTROLLER] Token válido pero no se encontró usuario en DB');
                _isLoggedIn.value = true;
                _startTokenRefreshTimer();
              }
            } else {
              debugPrint(
                  '[AUTH_CONTROLLER] No hay user_email almacenado. Marcando sesión como válida');
              _isLoggedIn.value = true;
              _startTokenRefreshTimer();
            }
          } else {
            debugPrint('[AUTH_CONTROLLER] Token inválido, limpiando sesión');
            await _clearStoredSession();
          }
        } catch (e) {
          debugPrint(
              '[AUTH_CONTROLLER] Error verificando token, limpiando sesión: $e');
          await _clearStoredSession();
        }
      } else {
        debugPrint(
            '[AUTH_CONTROLLER] No hay sesión persistente o usuario no eligió mantener sesión');
        if (accessToken != null && !keepLoggedIn) {
          debugPrint(
              '[AUTH_CONTROLLER] Limpiando tokens de sesión no persistente');
          await _clearStoredSession();
        }
      }
    } catch (e) {
      debugPrint('[AUTH_CONTROLLER] Error cargando sesión almacenada: $e');
      await _clearStoredSession();
    } finally {
      
      debugPrint('[AUTH_CONTROLLER] Marcando controlador como inicializado');
      _isInitialized.value = true;
      update(); 
    }
  }

  
  Future<void> _clearStoredSession() async {
    await _secureStorage.deleteAll();
    _currentUser.value = null;
    _isLoggedIn.value = false;
  }

  
  void setDatabase(String database) {
    _selectedDatabase.value = database;
    _errorMessage.value = '';
  }

  
  Future<bool> login({
    required String identifier,
    required String password,
    bool keepLoggedIn = false,
  }) async {
    if (_isLoading.value) return false;

    _setLoading(true);
    _errorMessage.value = '';

    try {
      debugPrint('[AUTH_CONTROLLER] Iniciando proceso de login');
      final isEmail = identifier.contains('@');
      final cleanIdentifier = identifier.trim();
      if (kDebugMode) {
        debugPrint('[AUTH_CONTROLLER] Identificador: "$cleanIdentifier"');
        debugPrint('[AUTH_CONTROLLER] Tipo: ${isEmail ? "EMAIL" : "USERNAME"}');
        debugPrint('[AUTH_CONTROLLER] Mantener sesión: $keepLoggedIn');
        debugPrint(
            '[AUTH_CONTROLLER] Timestamp: ${DateTime.now().toIso8601String()}');
      }

      
      final response = await _authService.login(
        email: cleanIdentifier,
        password: password,
      );

      debugPrint('[AUTH_CONTROLLER] Respuesta de login recibida exitosamente');
      if (kDebugMode) {
        debugPrint(
            '[AUTH_CONTROLLER] Respuesta contiene success: ${response.containsKey('success')}');
        debugPrint('[AUTH_CONTROLLER] Success value: ${response['success']}');
        debugPrint(
            '[AUTH_CONTROLLER] Contiene data: ${response.containsKey('data')}');
      }

      if (response['success'] == true && response['data'] != null) {
        debugPrint('[AUTH_CONTROLLER] Procesando datos de usuario');

        
        final userData = response['data'];
        if (kDebugMode) {
          debugPrint('[AUTH_CONTROLLER] Datos de usuario recibidos:');
          debugPrint('[AUTH_CONTROLLER]   - ID: ${userData['_id']}');
          debugPrint('[AUTH_CONTROLLER]   - Email: ${userData['email']}');
          debugPrint(
              '[AUTH_CONTROLLER]   - Nombre: ${userData['first_name']} ${userData['last_name']}');
          debugPrint('[AUTH_CONTROLLER]   - Username: ${userData['username']}');
        }

        final user = User(
          id: userData['_id'] ?? userData['id'] ?? '',
          studentId: userData['student_id'] ?? userData['studentId'] ?? '',
          email: userData['email'] ?? cleanIdentifier,
          firstName: userData['first_name'] ?? userData['firstName'] ?? '',
          lastName: userData['last_name'] ?? userData['lastName'] ?? '',
          username: userData['username'] ??
              (userData['email'] != null
                  ? userData['email'].toString().split('@')[0]
                  : cleanIdentifier),
          createdAt: userData['created_at'] != null
              ? DateTime.parse(userData['created_at'])
              : DateTime.now(),
        );

        print('AuthController: Usuario creado exitosamente: ${user.fullName}');

        _currentUser.value = user;
        _isLoggedIn.value = true;

        
        _startTokenRefreshTimer();

        print('AuthController: Guardando tokens en storage...');

        
        final accessToken = response['access_token'] ??
            response['token'] ??
            response['accessToken'];
        if (accessToken != null) {
          await _secureStorage.write(key: _accessTokenKey, value: accessToken);
          print('AuthController: AccessToken guardado');
        }

        
        final refreshToken =
            response['refresh_token'] ?? response['refreshToken'];
        if (refreshToken != null) {
          await _secureStorage.write(key: 'refresh_token', value: refreshToken);
          print('AuthController: RefreshToken guardado');
        }

        
        await _secureStorage.write(
            key: 'keep_logged_in', value: keepLoggedIn.toString());
        await _secureStorage.write(key: 'user_email', value: user.email);

        await _secureStorage.write(
            key: _databaseKey, value: _selectedDatabase.value);

        print('AuthController: Datos de sesión guardados exitosamente');

        _setLoading(false);
        update(); 

        print(
            'AuthController: Login completado exitosamente para: ${user.email}');
        print('=== LOGIN PROCESO COMPLETADO ===');

        Get.snackbar(
          'Bienvenido',
          'Sesión iniciada exitosamente',
          backgroundColor: const Color(0xFFFFD700),
          colorText: const Color(0xFF0D0D0D),
          snackPosition: SnackPosition.TOP,
        );

        return true;
      } else {
        print('AuthController: Error en respuesta de login');
        print('AuthController: Success: ${response['success']}');
        print('AuthController: Message: ${response['message']}');

        final errorMessage = response['message'] ?? 'Credenciales inválidas';
        _errorMessage.value = errorMessage;
        _setLoading(false);

        print('AuthController: Mostrando error al usuario: $errorMessage');

        Get.snackbar(
          'Error de autenticación',
          errorMessage,
          backgroundColor: Colors.red[400],
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );

        return false;
      }
    } catch (e) {
      print('AuthController: Excepción capturada en login: $e');
      print('AuthController: Tipo de error: ${e.runtimeType}');
      print(
          'AuthController: Timestamp del error: ${DateTime.now().toIso8601String()}');

      _errorMessage.value = 'Error de conexión: $e';
      _setLoading(false);

      print('=== LOGIN FALLÓ ===');

      Get.snackbar(
        'Error',
        'Error de conexión. Verifica tu internet.',
        backgroundColor: Colors.red[400],
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );

      return false;
    }
  }

  
  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? username,
  }) async {
    if (_isLoading.value) return false;

    _setLoading(true);
    _errorMessage.value = '';

    try {
      print(
          'AuthController: Intentando registro con verificación para email: $email');
      print('Nombre completo: $firstName $lastName');
      print('Timestamp registro: ${DateTime.now().toIso8601String()}');

      final fullName = '$firstName $lastName'.trim();

      
      final normalizedEmail = email.trim().toLowerCase();
      print('Email normalizado: "$normalizedEmail"');

      final response = await _authService.signup(
        email: normalizedEmail,
        password: password,
        name: fullName,
      );

      print('AuthController: Registro response recibido: $response');

      if (response['success'] == true || response.containsKey('message')) {
        _setLoading(false);

        print('Navegando a verificación con email: "$normalizedEmail"');

        
        Get.toNamed('/email-verification', arguments: {
          'email': normalizedEmail, 
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
          'username': username,
        });

        return true;
      } else {
        final errorMessage = response['message'] ?? 'Error en registro';
        _errorMessage.value = errorMessage;
        _setLoading(false);

        Get.snackbar(
          'Error de registro',
          errorMessage,
          backgroundColor: Colors.red[400],
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );

        return false;
      }
    } catch (e) {
      print('AuthController: Error en registro: $e');
      _errorMessage.value = 'Error de conexión: $e';
      _setLoading(false);

      Get.snackbar(
        'Error',
        'Error de conexión. Verifica tu internet.',
        backgroundColor: Colors.red[400],
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );

      return false;
    }
  }

  
  
  Future<bool> verifyEmailAndComplete({
    required String email,
    required String code,
    required String password,
    required String firstName,
    required String lastName,
    String? username,
  }) async {
    _setLoading(true);

    try {
      print('AuthController: Verificando código de email...');
      print('Email a verificar: "$email"');
      print('Código recibido: "$code"');
      print('Timestamp verificación: ${DateTime.now().toIso8601String()}');

      
      final normalizedEmail = email.trim().toLowerCase();
      print('Email normalizado para verificación: "$normalizedEmail"');

      final response = await _authService.verifyEmail(
        email: normalizedEmail,
        code: code,
      );

      print('Response completa de verify-email: $response');

      
      
      if (response['success'] == true) {
        print('AuthController: Email verificado exitosamente por ROBLE');
        print('Iniciando proceso de login automático...');

        
        print('Paso 1: Obteniendo token temporal del auth de ROBLE...');

        try {
          final authResponse = await _authService.loginAuth(
            email: normalizedEmail,
            password: password,
          );

          print('Response del auth de ROBLE: $authResponse');

          if (authResponse.containsKey('accessToken') &&
              authResponse['accessToken'] != null) {
            print('Token temporal obtenido exitosamente');

            final tempAccessToken = authResponse['accessToken'];
            final authUserData = authResponse['user'];

            
            print('Paso 2: Creando usuario en tabla users...');
            try {
              final userCreationResponse =
                  await _authService.createUserInDatabase(
                accessToken: tempAccessToken,
                email: normalizedEmail,
                firstName: firstName,
                lastName: lastName,
                username: username ?? normalizedEmail.split('@')[0],
                studentId: authUserData?['id'] ?? '',
              );

              print('Usuario creado en database: $userCreationResponse');
            } catch (userCreationError) {
              print('Error creando usuario en database: $userCreationError');

              
              final existingUser = await _authService.getUserFromDatabase(
                accessToken: tempAccessToken,
                email: normalizedEmail,
              );

              if (existingUser != null) {
                print('Usuario ya existe en database, continuando...');
              } else {
                throw Exception('No se pudo crear usuario en base de datos');
              }
            }

            
            print(
                'Paso 3: Haciendo login con nueva lógica contra tabla users...');
            final finalLoginResponse = await _authService.login(
              email: normalizedEmail,
              password: password,
            );

            print('Response de login final: $finalLoginResponse');

            if (finalLoginResponse['success'] == true &&
                finalLoginResponse['data'] != null) {
              
              final userDataFromTable = finalLoginResponse['data'];

              
              final user = User(
                id: userDataFromTable['_id'] ?? '',
                studentId: userDataFromTable['student_id'] ?? '',
                email: userDataFromTable['email'] ?? normalizedEmail,
                firstName: userDataFromTable['first_name'] ?? firstName,
                lastName: userDataFromTable['last_name'] ?? lastName,
                username: userDataFromTable['username'] ??
                    (username ?? normalizedEmail.split('@')[0]),
                createdAt: userDataFromTable['created_at'] != null
                    ? DateTime.parse(userDataFromTable['created_at'])
                    : DateTime.now(),
              );

              print(
                  'Usuario obtenido de tabla users: ${user.email} (${user.firstName} ${user.lastName})');

              _currentUser.value = user;
              _isLoggedIn.value = true;

              
              _startTokenRefreshTimer();

              
              final finalAccessToken = finalLoginResponse['accessToken'];
              final finalRefreshToken = finalLoginResponse['refreshToken'];

              if (finalAccessToken != null) {
                await _secureStorage.write(
                    key: _accessTokenKey, value: finalAccessToken);
                print('AccessToken final guardado');
              }
              if (finalRefreshToken != null) {
                await _secureStorage.write(
                    key: _refreshTokenKey, value: finalRefreshToken);
                print('RefreshToken final guardado');
              }
              await _secureStorage.write(
                  key: _databaseKey, value: _selectedDatabase.value);
              print('Database key guardada');

              
              await _secureStorage.write(key: 'keep_logged_in', value: 'true');
              await _secureStorage.write(key: 'user_email', value: user.email);
              print('Preferencias de sesión persistente guardadas');

              _setLoading(false);
              update();

              print(
                  'Registro completado exitosamente con nueva lógica, navegando a Home...');

              Get.snackbar(
                'Registro exitoso',
                'Email verificado y cuenta creada correctamente',
                backgroundColor: const Color(0xFFFFD700),
                colorText: const Color(0xFF0D0D0D),
                snackPosition: SnackPosition.TOP,
              );

              
              Get.offAllNamed('/home');
              return true;
            } else {
              print('Login final falló - Response: $finalLoginResponse');
              _setLoading(false);

              Get.snackbar(
                'Email verificado',
                'Tu cuenta ha sido verificada. Ahora puedes iniciar sesión manualmente.',
                backgroundColor: const Color(0xFFFFD700),
                colorText: const Color(0xFF0D0D0D),
                snackPosition: SnackPosition.TOP,
              );

              
              Get.offAllNamed('/login');
              return true;
            }
          } else {
            print('Login con auth de ROBLE falló');
            _setLoading(false);

            Get.snackbar(
              'Error',
              'No se pudo completar el registro. Intenta iniciar sesión manualmente.',
              backgroundColor: Colors.red[400],
              colorText: Colors.white,
              snackPosition: SnackPosition.TOP,
            );

            Get.offAllNamed('/login');
            return false;
          }
        } catch (loginError) {
          print('Error en login automático: $loginError');
          _setLoading(false);

          Get.snackbar(
            'Email verificado',
            'Tu cuenta ha sido verificada. Ahora puedes iniciar sesión manualmente.',
            backgroundColor: const Color(0xFFFFD700),
            colorText: const Color(0xFF0D0D0D),
            snackPosition: SnackPosition.TOP,
          );

          
          Get.offAllNamed('/login');
          return true;
        }
      } else {
        print('Verificación fallida - Response: $response');
        _setLoading(false);

        Get.snackbar(
          'Código inválido',
          'El código de verificación no es correcto. Inténtalo de nuevo.',
          backgroundColor: Colors.red[400],
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
        return false;
      }
    } catch (e) {
      print('AuthController: Error verificando email: $e');
      _setLoading(false);

      String errorMessage =
          'No se pudo verificar el email. Inténtalo de nuevo.';

      
      if (e.toString().contains('expirado')) {
        errorMessage =
            'El código ha expirado. Presiona "Reenviar" para obtener uno nuevo.';
      } else if (e.toString().contains('incorrecto') ||
          e.toString().contains('inválido')) {
        errorMessage =
            'Código incorrecto. Verifica los números e inténtalo de nuevo.';
      } else if (e.toString().contains('conexión') ||
          e.toString().contains('network')) {
        errorMessage =
            'Error de conexión. Verifica tu internet e inténtalo de nuevo.';
      }

      Get.snackbar(
        'Error de verificación',
        errorMessage,
        backgroundColor: Colors.red[400],
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 5),
      );
      return false;
    }
  }

  
  Future<bool> forgotPassword({required String email}) async {
    if (_isLoading.value) return false;

    _setLoading(true);
    _errorMessage.value = '';

    try {
      
      print(
          'AuthController: Solicitud de recuperación de contraseña para: $email');

      
      await Future.delayed(const Duration(seconds: 2));

      _setLoading(false);

      Get.snackbar(
        'Función no disponible',
        'La recuperación de contraseña estará disponible pronto',
        backgroundColor: Colors.orange[400],
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );

      return true;
    } catch (e) {
      print('AuthController: Error en forgotPassword: $e');
      _errorMessage.value = 'Error de conexión: $e';
      _setLoading(false);

      Get.snackbar(
        'Error',
        'Error de conexión. Verifica tu internet.',
        backgroundColor: Colors.red[400],
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );

      return false;
    }
  }

  
  Future<void> logout() async {
    _setLoading(true);

    try {
      
      debugPrint('[AUTH_CONTROLLER] Cerrando sesión');

      
      await Future.delayed(const Duration(seconds: 1));
    } catch (e) {
      debugPrint('[AUTH_CONTROLLER] Error durante logout: $e');
    } finally {
      
      await _clearStoredSession();

      
      _stopTokenRefreshTimer();

      _setLoading(false);
      update();

      
      try {
        Get.offAllNamed(AppRoutes.login);
      } catch (_) {
        
        Get.offAll(() => const LoginPage());
      }

      Get.snackbar(
        'Sesión cerrada',
        'Has cerrado sesión correctamente',
        backgroundColor: const Color(0xFFFFD700),
        colorText: const Color(0xFF0D0D0D),
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  
  void loginAsGuest() {
    _currentUser.value = null;
    _isLoggedIn.value = true; 

    Get.snackbar(
      'Modo invitado',
      'Navegando sin autenticación',
      backgroundColor: Colors.grey[600],
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
    );
  }

  
  void _setLoading(bool loading) {
    _isLoading.value = loading;
  }

  
  void clearError() {
    _errorMessage.value = '';
  }

  
  Future<String?> getAccessToken() async {
    try {
      return await _secureStorage.read(key: _accessTokenKey);
    } catch (_) {
      return null;
    }
  }

  
  Future<bool> refreshAccessToken() async {
    try {
      final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
      if (refreshToken == null) {
        debugPrint('[AUTH] No hay refresh token almacenado');
        return false;
      }

      final result = await _authService.refreshAccessToken(refreshToken);
      if (result != null) {
        
        await _secureStorage.write(
            key: _accessTokenKey, value: result['accessToken']);

        
        if (result['refreshToken'] != null) {
          await _secureStorage.write(
              key: _refreshTokenKey, value: result['refreshToken']);
        }

        debugPrint('[AUTH] Access token renovado exitosamente');
        return true;
      } else {
        debugPrint('[AUTH] Error renovando access token');
        return false;
      }
    } catch (e) {
      debugPrint('[AUTH] Excepción renovando access token: $e');
      return false;
    }
  }

  
  Future<bool> handle401Error() async {
    debugPrint('[AUTH] Manejando error 401, intentando renovar token...');
    final success = await refreshAccessToken();

    if (!success) {
      
      debugPrint('[AUTH] No se pudo renovar el token, cerrando sesión');
      await logout();
    }

    return success;
  }

  
  void _startTokenRefreshTimer() {
    _stopTokenRefreshTimer(); 

    _tokenRefreshTimer =
        Timer.periodic(const Duration(minutes: 12), (timer) async {
      if (isLoggedIn) {
        debugPrint('[AUTH] Renovación automática de token programada');
        await refreshAccessToken();
      } else {
        debugPrint(
            '[AUTH] Usuario no logueado, cancelando timer de renovación');
        _stopTokenRefreshTimer();
      }
    });

    debugPrint(
        '[AUTH] Timer de renovación automática iniciado (cada 12 minutos)');
  }

  
  void _stopTokenRefreshTimer() {
    _tokenRefreshTimer?.cancel();
    _tokenRefreshTimer = null;
  }

  @override
  void onClose() {
    _stopTokenRefreshTimer();
    super.onClose();
  }

  
  List<String> getAvailableDatabases() {
    return [
      'uninorte',
      'unisimon',
      'uac',
      'unicolmayor',
      'unipiloto',
      'uniremington',
    ];
  }

  
  String getDatabaseDisplayName(String dbName) {
    switch (dbName.toLowerCase()) {
      case 'uninorte':
        return 'Universidad del Norte';
      case 'unisimon':
        return 'Universidad Simón Bolívar';
      case 'uac':
        return 'Universidad Autónoma del Caribe';
      case 'unicolmayor':
        return 'Universidad Colegio Mayor de Cundinamarca';
      case 'unipiloto':
        return 'Universidad Piloto de Colombia';
      case 'uniremington':
        return 'Universidad Remington';
      default:
        return dbName.toUpperCase();
    }
  }

  
  Future<bool> requestPasswordReset(String email) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final result = await _authService.requestPasswordReset(email: email);

      if (result['success'] == true) {
        Get.snackbar(
          'Éxito',
          'Se ha enviado un enlace de recuperación a tu correo electrónico.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        return true;
      } else {
        _errorMessage.value =
            result['message'] ?? 'Error al solicitar el reset de contraseña';
        return false;
      }
    } catch (e) {
      _errorMessage.value = 'Error de conexión: ${e.toString()}';
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  String? extractTokenFromUrl(String url) {
    try {
      return _authService.extractTokenFromResetUrl(url);
    } catch (e) {
      _errorMessage.value = 'URL inválida: ${e.toString()}';
      return null;
    }
  }

  Future<bool> validateResetToken(String token) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final result = await _authService.validateResetToken(token);

      if (!result) {
        _errorMessage.value = 'Token inválido o expirado';
        return false;
      }

      return true;
    } catch (e) {
      _errorMessage.value = 'Error al validar el token: ${e.toString()}';
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> resetPassword(String token, String newPassword) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final result = await _authService.resetPassword(
          token: token, newPassword: newPassword);

      if (result['success'] == true) {
        Get.snackbar(
          'Éxito',
          'Tu contraseña ha sido actualizada correctamente.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        return true;
      } else {
        _errorMessage.value =
            result['message'] ?? 'Error al cambiar la contraseña';
        return false;
      }
    } catch (e) {
      _errorMessage.value = 'Error de conexión: ${e.toString()}';
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  
  Future<bool> checkEmailAvailable(String email) async {
    try {
      final res = await _authService.isEmailAvailable(email);
      print('AuthController.checkEmailAvailable("$email") => $res');
      return res;
    } catch (e) {
      print('AuthController.checkEmailAvailable error: $e');
      return false; 
    }
  }

  Future<bool> checkUsernameAvailable(String username) async {
    try {
      final res = await _authService.isUsernameAvailable(username);
      print('AuthController.checkUsernameAvailable("$username") => $res');
      return res;
    } catch (e) {
      print('AuthController.checkUsernameAvailable error: $e');
      return false;
    }
  }
}
