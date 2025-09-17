import 'package:flutter/material.dart';
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

  // cuando abre la app reviso si ya tenía sesión guardada
  Future<void> _loadStoredSession() async {
    try {
      print('Iniciando carga de sesión...');

      final accessToken = await _secureStorage.read(key: _accessTokenKey);
      final storedDatabase = await _secureStorage.read(key: _databaseKey);
      final keepLoggedInStr = await _secureStorage.read(key: 'keep_logged_in');
      final keepLoggedIn = keepLoggedInStr == 'true';

      print(
          'Datos encontrados - Token: ${accessToken != null}, Database: ${storedDatabase != null}, KeepLoggedIn: $keepLoggedIn');

      if (accessToken != null && storedDatabase != null && keepLoggedIn) {
        print('Restaurando sesión persistente...');
        _selectedDatabase.value = storedDatabase;

        try {
          // verifico que el token siga siendo válido en el servidor
          final tokenCheck =
              await _authService.verifyToken(accessToken: accessToken);
          final valid =
              tokenCheck['valid'] == true || tokenCheck['success'] == true;
          if (valid) {
            final storedEmail = await _secureStorage.read(key: 'user_email');
            if (storedEmail != null && storedEmail.isNotEmpty) {
              // busco los datos del usuario en la base de datos
              final dbUser = await _authService.getUserFromDatabase(
                accessToken: accessToken,
                email: storedEmail,
              );
              if (dbUser != null) {
                // creo el objeto User con la info de la DB
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
                print('Sesión restaurada exitosamente desde DB');
              } else {
                print('Token válido pero no se encontró usuario en DB');
                _isLoggedIn.value = true;
              }
            } else {
              print(
                  'No hay user_email almacenado. Marcando sesión como válida.');
              _isLoggedIn.value = true;
            }
          } else {
            print('Token inválido, limpiando sesión...');
            await _clearStoredSession();
          }
        } catch (e) {
          print('Error verificando token, limpiando sesión: $e');
          await _clearStoredSession();
        }
      } else {
        print(
            'No hay sesión persistente o usuario no eligió mantener sesión');
        if (accessToken != null && !keepLoggedIn) {
          print('Limpiando tokens de sesión no persistente...');
          await _clearStoredSession();
        }
      }
    } catch (e) {
      print('Error loading stored session: $e');
      await _clearStoredSession();
    } finally {
      // IMPORTANTE: siempre marco como inicializado para que la UI sepa que ya terminé
      print('Marcando como inicializado');
      _isInitialized.value = true;
      update(); // le aviso a GetBuilder que cambió algo
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

  // login principal - acepta email o username
  Future<bool> login({
    required String identifier,
    required String password,
    bool keepLoggedIn = false,
  }) async {
    if (_isLoading.value) return false;

    _setLoading(true);
    _errorMessage.value = '';

    try {
      final isEmail = identifier.contains('@');
      final emailToUse = identifier.trim();
      print(
          'AuthController: Intentando login con: $identifier (isEmail=$isEmail)');

      final response = await _authService.login(
        email: emailToUse,
        password: password,
      );

      print('AuthController: Login response recibido');

      if (response['success'] == true && response['data'] != null) {
        // construyo el objeto User con lo que me devuelve ROBLE
        final userData = response['data'];
        final user = User(
          id: userData['_id'] ?? userData['id'] ?? '',
          studentId: userData['student_id'] ?? userData['studentId'] ?? '',
          email: userData['email'] ?? emailToUse,
          firstName: userData['first_name'] ?? userData['firstName'] ?? '',
          lastName: userData['last_name'] ?? userData['lastName'] ?? '',
          username: userData['username'] ??
              (userData['email'] != null
                  ? userData['email'].toString().split('@')[0]
                  : identifier),
          createdAt: userData['created_at'] != null
              ? DateTime.parse(userData['created_at'])
              : DateTime.now(),
        );

        _currentUser.value = user;
        _isLoggedIn.value = true;

        // guardo el token que me devolvió ROBLE
        final accessToken = response['access_token'] ??
            response['token'] ??
            response['accessToken'];
        if (accessToken != null) {
          await _secureStorage.write(key: _accessTokenKey, value: accessToken);
        }

        // si hay refresh token también lo guardo
        final refreshToken =
            response['refresh_token'] ?? response['refreshToken'];
        if (refreshToken != null) {
          await _secureStorage.write(key: 'refresh_token', value: refreshToken);
        }

        // guardo si el usuario quiere mantener la sesión y su email
        await _secureStorage.write(
            key: 'keep_logged_in', value: keepLoggedIn.toString());
        await _secureStorage.write(key: 'user_email', value: user.email);

        await _secureStorage.write(
            key: _databaseKey, value: _selectedDatabase.value);

        _setLoading(false);
        update(); // aviso a la UI que cambió algo

        Get.snackbar(
          'Bienvenido',
          'Sesión iniciada exitosamente',
          backgroundColor: const Color(0xFFFFD700),
          colorText: const Color(0xFF0D0D0D),
          snackPosition: SnackPosition.TOP,
        );

        return true;
      } else {
        final errorMessage = response['message'] ?? 'Error en login';
        _errorMessage.value = errorMessage;
        _setLoading(false);

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
      print('AuthController: Error en login: $e');
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

  // este método maneja todo después de que el usuario pone el código
  // verifica el email, hace login automático y crea el usuario en mi DB
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

        // hago login automático para obtener el token
        print('Haciendo login automático después de verificación...');

        try {
          final loginResponse = await _authService.login(
            email: normalizedEmail,
            password: password,
          );

          print('Response de login automático: $loginResponse');

          // ROBLE me devuelve directamente accessToken, refreshToken y user
          if (loginResponse.containsKey('accessToken') &&
              loginResponse['accessToken'] != null) {
            print('Login automático exitoso');

            // saco los tokens de la respuesta
            final accessToken = loginResponse['accessToken'];
            final refreshToken = loginResponse['refreshToken'];
            final userData = loginResponse['user'];

            print(
                'AccessToken recibido: ${accessToken != null ? "SÍ" : "NO"}');
            print(
                'RefreshToken recibido: ${refreshToken != null ? "SÍ" : "NO"}');
            print('Datos de usuario recibidos: $userData');

            if (accessToken == null) {
              throw Exception('No se recibió accessToken');
            }

            // creo el usuario en mi propia base de datos
            print('Creando usuario en base de datos...');
            try {
              final userCreationResponse =
                  await _authService.createUserInDatabase(
                accessToken: accessToken,
                email: normalizedEmail,
                firstName: firstName,
                lastName: lastName,
                username: username ?? normalizedEmail.split('@')[0],
                password: password,
                studentId: userData?['id'] ?? '',
              );

              print('Usuario creado en database: $userCreationResponse');
            } catch (userCreationError) {
              print('Error creando usuario en database: $userCreationError');

              // reviso si el usuario ya existía (por si fue un segundo intento)
              try {
                final existingUser = await _authService.getUserFromDatabase(
                  accessToken: accessToken,
                  email: normalizedEmail,
                );

                if (existingUser != null) {
                  print('Usuario ya existe en database: $existingUser');
                } else {
                  print(
                      'No se pudo crear ni encontrar usuario en database. Se continuará con la sesión para no bloquear al usuario.');
                  // TODO: meter esto en una cola para reintentarlo después
                }
              } catch (e) {
                print(
                    'Error comprobando existencia de usuario en database: $e');
              }
            }

            // creo el objeto User con los datos que recibí
            final user = User(
              id: userData?['id'] ?? '',
              studentId:
                  userData?['id'] ?? '', // uso el ID como studentId por ahora
              email: userData?['email'] ?? normalizedEmail,
              firstName: firstName, // uso los datos del formulario
              lastName: lastName, // uso los datos del formulario
              username: username ?? normalizedEmail.split('@')[0],
              createdAt: DateTime.now(), // fecha actual
            );

            print(
                'Usuario creado localmente: ${user.email} (${user.firstName} ${user.lastName})');

            _currentUser.value = user;
            _isLoggedIn.value = true;

            // guardo todos los tokens
            if (accessToken != null) {
              await _secureStorage.write(
                  key: _accessTokenKey, value: accessToken);
              print('AccessToken guardado');
            }
            if (refreshToken != null) {
              await _secureStorage.write(
                  key: _refreshTokenKey, value: refreshToken);
              print('RefreshToken guardado');
            }
            await _secureStorage.write(
                key: _databaseKey, value: _selectedDatabase.value);
            print('Database key guardada');

            // por defecto mantengo la sesión iniciada después del registro
            await _secureStorage.write(key: 'keep_logged_in', value: 'true');
            await _secureStorage.write(key: 'user_email', value: user.email);
            print(
                'Preferencias de sesión persistente guardadas (keep_logged_in=true, user_email)');

            _setLoading(false);
            update();

            print('Registro completado exitosamente, navegando a Home...');

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
            print('Login automático falló - Response: $loginResponse');
            // verificación ok pero login falló
            print('Verificación exitosa pero login automático falló');
            _setLoading(false);

            Get.snackbar(
              'Email verificado',
              'Tu cuenta ha sido verificada. Ahora puedes iniciar sesión.',
              backgroundColor: const Color(0xFFFFD700),
              colorText: const Color(0xFF0D0D0D),
              snackPosition: SnackPosition.TOP,
            );

            // regreso al login
            Get.offAllNamed('/login');
            return true;
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

  // cerrar sesión y limpiar todo
  Future<void> logout() async {
    _setLoading(true);

    try {
      // TODO: cuando ROBLE tenga endpoint de logout lo llamo acá
      print('AuthController: Cerrando sesión...');

      // simulo delay
      await Future.delayed(const Duration(seconds: 1));
    } catch (e) {
      print('Error durante logout: $e');
    } finally {
      // limpio todo local sin importar si el server respondió
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
}
