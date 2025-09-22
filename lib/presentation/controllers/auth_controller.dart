import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/services/roble_service.dart';
import '../../domain/models/user.dart';

class AuthController extends GetxController {
  final RobleService _authService;
  static const _secureStorage = FlutterSecureStorage();

  // Variables reactivas que manejo con GetX
  final _isLoggedIn = false.obs;
  final _isLoading = false.obs;
  final _isInitialized = false
      .obs; // necesito esto para saber cuando termina de revisar si hay sesión guardada
  final _currentUser = Rxn<User>();
  final _errorMessage = ''.obs;
  final _selectedDatabase = 'uninorte'.obs; // por defecto uso uninorte

  // estos getters me facilitan acceder a los valores sin .value
  bool get isLoggedIn => _isLoggedIn.value;
  bool get isLoading => _isLoading.value;
  bool get isInitialized => _isInitialized.value;
  User? get currentUser => _currentUser.value;
  String get errorMessage => _errorMessage.value;
  String get selectedDatabase => _selectedDatabase.value;

  // keys que uso para guardar cosas en el storage del teléfono
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _databaseKey = 'selected_database';

  AuthController(this._authService);

  @override
  void onInit() {
    super.onInit();
    _loadStoredSession();
  }

  // Verificas si ya existe una sesión guardada al abrir la app
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
          // Verificas que el token siga siendo válido en el servidor
          final tokenCheck =
              await _authService.verifyToken(accessToken: accessToken);
          final valid =
              tokenCheck['valid'] == true || tokenCheck['success'] == true;
          if (valid) {
            final storedEmail = await _secureStorage.read(key: 'user_email');
            if (storedEmail != null && storedEmail.isNotEmpty) {
              // Buscas los datos del usuario en la base de datos
              final dbUser = await _authService.getUserFromDatabase(
                accessToken: accessToken,
                email: storedEmail,
              );
              if (dbUser != null) {
                // Creas el objeto User con la info de la DB
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
                debugPrint(
                    '[AUTH_CONTROLLER] Sesión restaurada exitosamente desde DB');
              } else {
                debugPrint(
                    '[AUTH_CONTROLLER] Token válido pero no se encontró usuario en DB');
                _isLoggedIn.value = true;
              }
            } else {
              debugPrint(
                  '[AUTH_CONTROLLER] No hay user_email almacenado. Marcando sesión como válida');
              _isLoggedIn.value = true;
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
      // IMPORTANTE: siempre marcas como inicializado para que la UI sepa que ya terminaste
      debugPrint('[AUTH_CONTROLLER] Marcando controlador como inicializado');
      _isInitialized.value = true;
      update(); // Le avisas a GetBuilder que cambió algo
    }
  }

  // borro toda la info guardada en el teléfono
  Future<void> _clearStoredSession() async {
    await _secureStorage.deleteAll();
    _currentUser.value = null;
    _isLoggedIn.value = false;
  }

  // cambio la universidad seleccionada
  void setDatabase(String database) {
    _selectedDatabase.value = database;
    _errorMessage.value = '';
  }

  // login principal - acepta email o username (nueva implementacion)
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

      // Usas el método de login que valida contra la base de datos
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

        // Construyes el objeto User con los datos de la base de datos
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

        print('AuthController: Guardando tokens en storage...');

        // guardo el token personalizado
        final accessToken = response['access_token'] ??
            response['token'] ??
            response['accessToken'];
        if (accessToken != null) {
          await _secureStorage.write(key: _accessTokenKey, value: accessToken);
          print('AuthController: AccessToken guardado');
        }

        // guardo refresh token
        final refreshToken =
            response['refresh_token'] ?? response['refreshToken'];
        if (refreshToken != null) {
          await _secureStorage.write(key: 'refresh_token', value: refreshToken);
          print('AuthController: RefreshToken guardado');
        }

        // guardo preferencias de sesion y datos del usuario
        await _secureStorage.write(
            key: 'keep_logged_in', value: keepLoggedIn.toString());
        await _secureStorage.write(key: 'user_email', value: user.email);

        await _secureStorage.write(
            key: _databaseKey, value: _selectedDatabase.value);

        print('AuthController: Datos de sesión guardados exitosamente');

        _setLoading(false);
        update(); // aviso a la UI que cambió algo

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

  // registro inicial - solo manda el email para verificación
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

      // limpio el email por si tiene espacios o mayúsculas
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

        // voy a la pantalla donde pone el código de verificación
        Get.toNamed('/email-verification', arguments: {
          'email': normalizedEmail, // Usar email normalizado
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

  // Verifica el email con el código y completa el registro del usuario
  // Verifica el email, hace login automático y crea el usuario en la DB
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

      // normalizo el email igual que en el registro
      final normalizedEmail = email.trim().toLowerCase();
      print('Email normalizado para verificación: "$normalizedEmail"');

      final response = await _authService.verifyEmail(
        email: normalizedEmail,
        code: code,
      );

      print('Response completa de verify-email: $response');

      // ROBLE ya creó el usuario cuando verificó el email
      // ahora hago login automático
      if (response['success'] == true) {
        print('AuthController: Email verificado exitosamente por ROBLE');
        print('Iniciando proceso de login automático...');

        // hago login con auth de ROBLE solo para obtener token temporal
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

            // paso 2: crear el usuario en mi propia base de datos
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

              // reviso si el usuario ya existía (por si fue un segundo intento)
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

            // paso 3: ahora hago login con la nueva logica (validando contra tabla users)
            print(
                'Paso 3: Haciendo login con nueva lógica contra tabla users...');
            final finalLoginResponse = await _authService.login(
              email: normalizedEmail,
              password: password,
            );

            print('Response de login final: $finalLoginResponse');

            if (finalLoginResponse['success'] == true &&
                finalLoginResponse['data'] != null) {
              // ahora tengo los datos reales de la tabla users
              final userDataFromTable = finalLoginResponse['data'];

              // creo el objeto User con los datos de la tabla users
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

              // guardo los tokens del login final (no los temporales del auth)
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

              // por defecto mantengo la sesión iniciada después del registro
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

              // voy directo al home
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

              // regreso al login
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

          // regreso al login
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

      // Manejar errores específicos
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

  // recuperar contraseña - todavía no implementado
  Future<bool> forgotPassword({required String email}) async {
    if (_isLoading.value) return false;

    _setLoading(true);
    _errorMessage.value = '';

    try {
      // TODO: cuando ROBLE tenga endpoint de forgot password lo conecto acá
      print(
          'AuthController: Solicitud de recuperación de contraseña para: $email');

      // simulo que tarda un poco
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

  // Cierra la sesión y limpia todos los datos almacenados
  Future<void> logout() async {
    _setLoading(true);

    try {
      // TODO: cuando ROBLE tenga endpoint de logout lo conectas acá
      debugPrint('[AUTH_CONTROLLER] Cerrando sesión');

      // Simulas delay
      await Future.delayed(const Duration(seconds: 1));
    } catch (e) {
      debugPrint('[AUTH_CONTROLLER] Error durante logout: $e');
    } finally {
      // Limpias todo local sin importar si el server respondió
      await _clearStoredSession();
      _setLoading(false);
      update();

      Get.snackbar(
        'Sesión cerrada',
        'Has cerrado sesión correctamente',
        backgroundColor: const Color(0xFFFFD700),
        colorText: const Color(0xFF0D0D0D),
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  // entrar como invitado sin autenticación
  void loginAsGuest() {
    _currentUser.value = null;
    _isLoggedIn.value = true; // permito navegar sin auth

    Get.snackbar(
      'Modo invitado',
      'Navegando sin autenticación',
      backgroundColor: Colors.grey[600],
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
    );
  }

  // cambio el estado de loading
  void _setLoading(bool loading) {
    _isLoading.value = loading;
  }

  // limpio mensajes de error
  void clearError() {
    _errorMessage.value = '';
  }

  // universidades que manejo
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

  // nombres bonitos para mostrar en la UI
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

  // Funciones para gestión de restablecimiento de contraseña
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

  // ===== Disponibilidad (expuestos para la UI) =====
  Future<bool> checkEmailAvailable(String email) async {
    try {
      final res = await _authService.isEmailAvailable(email);
      print('AuthController.checkEmailAvailable("$email") => $res');
      return res;
    } catch (e) {
      print('AuthController.checkEmailAvailable error: $e');
      return false; // fail-closed
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
