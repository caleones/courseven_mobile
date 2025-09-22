import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Gestiona todas las operaciones de comunicación con la API de ROBLE
class RobleService {
  // Hard-coded fallbacks to avoid any dotenv dependency during startup
  static const String _fallbackAuthUrl =
      'https://roble-api.openlab.uninorte.edu.co/auth';
  static const String _fallbackDbUrl =
      'https://roble-api.openlab.uninorte.edu.co/database';
  static const String _fallbackDbName = 'courseven_66a52df881';

  // Cached values to avoid repeated dotenv calls
  String? _cachedAuthUrl;
  String? _cachedDbUrl;
  String? _cachedDbName;
  String? _cachedReadonlyEmail;
  String? _cachedReadonlyPassword;
  bool _envInitialized =
      false; // tracks if we've successfully observed dotenv initialized at least once

  // Safe env accessor with initialization check
  String? _env(String key) {
    // Nunca accedes directamente a dotenv.env; solo verificas el flag expuesto por el paquete
    // y usas maybeGet que es seguro y retorna null cuando falta la clave
    if (!_envInitialized) {
      if (dotenv.isInitialized) {
        _envInitialized = true;
      } else {
        // Mantienes este log ligero para evitar spam mientras la app inicia
        debugPrint(
            '[ENV] Variables de entorno no inicializadas aún para "$key", usando fallback');
        return null;
      }
    }
    try {
      return dotenv.maybeGet(key);
    } catch (e) {
      // Extremadamente defensivo: si la llamada subyacente falla por cualquier razón, retorna null
      debugPrint('[ENV] Error accediendo variable "$key": $e');
      return null;
    }
  }

  // Getters with caching and fallbacks
  String get _baseAuthUrl {
    _cachedAuthUrl ??= _env('ROBLE_AUTH_BASE_URL') ?? _fallbackAuthUrl;
    return _cachedAuthUrl!;
  }

  String get _baseDatabaseUrl {
    _cachedDbUrl ??= _env('ROBLE_DB_BASE_URL') ?? _fallbackDbUrl;
    return _cachedDbUrl!;
  }

  String get _dbName {
    _cachedDbName ??= _env('ROBLE_DB_NAME') ?? _fallbackDbName;
    return _cachedDbName!;
  }

  // headers básicos que necesitas en todas las peticiones HTTP
  Map<String, String> get _baseHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // headers con autenticación cuando necesitas enviar el token de acceso
  Map<String, String> _authHeaders(String token) => {
        ..._baseHeaders,
        'Authorization': 'Bearer $token',
      };

  // ========== AUTENTICACIÓN ==========

  // Valida credenciales de usuario contra la base de datos y sistema de autenticación
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('[AUTH] Iniciando proceso de autenticación');
      debugPrint('[AUTH] Identificador recibido: $email');
      if (kDebugMode) {
        debugPrint(
            '[AUTH] Password: ${password.isNotEmpty ? "[PRESENTE]" : "[VACÍO]"}');
      }

      final isEmail = email.contains('@');
      debugPrint(
          '[AUTH] Tipo de identificador: ${isEmail ? "EMAIL" : "USERNAME"}');

      String emailForAuth;

      if (isEmail) {
        // Caso 1: recibiste un email, lo usas directamente para autenticación
        emailForAuth = email;
        debugPrint('[AUTH] Usando email directamente: $emailForAuth');
      } else {
        // Caso 2: recibiste un username, necesitas encontrar el email correspondiente
        debugPrint(
            '[AUTH] Username detectado, buscando email en base de datos');

        // Para buscar por username, necesitas un token temporal
        // Usas credenciales que sabes que existen en el sistema de auth
        debugPrint('[AUTH] Obteniendo token temporal para consulta');
        final roEmail = _env('ROBLE_READONLY_EMAIL');
        final roPass = _env('ROBLE_READONLY_PASSWORD');
        if (roEmail == null || roPass == null) {
          throw Exception(
              'Faltan ROBLE_READONLY_EMAIL o ROBLE_READONLY_PASSWORD en .env');
        }
        final tempAuthResponse = await loginAuth(
          email: roEmail,
          password: roPass,
        );

        final tempToken = tempAuthResponse['accessToken'];
        if (tempToken == null) {
          throw Exception('No se pudo obtener token temporal');
        }

        // Buscas el usuario por username para obtener su email
        debugPrint('[AUTH] Consultando usuario por username: $email');
        final url = '$_baseDatabaseUrl/$_dbName/read';
        final response = await http.get(
          Uri.parse('$url?tableName=users&username=$email'),
          headers: _authHeaders(tempToken),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is List && data.isNotEmpty) {
            final userData = data[0] as Map<String, dynamic>;
            emailForAuth = userData['email'];
            debugPrint(
                '[AUTH] Email encontrado para username $email: $emailForAuth');
          } else {
            throw Exception('Usuario no encontrado');
          }
        } else {
          throw Exception('Error buscando usuario por username');
        }
      }

      // Realizas login con el email correcto en el sistema de autenticación ROBLE
      debugPrint('[AUTH] Autenticando con email: $emailForAuth');
      final authResponse =
          await loginAuth(email: emailForAuth, password: password);

      final accessToken = authResponse['accessToken'];
      if (accessToken == null) {
        throw Exception('No se recibió token de acceso del auth');
      }

      debugPrint('[AUTH] Token de acceso obtenido exitosamente');

      // Buscas los datos completos del usuario en la tabla users
      debugPrint('[AUTH] Obteniendo datos completos del usuario');
      final url = '$_baseDatabaseUrl/$_dbName/read';
      final response = await http.get(
        Uri.parse('$url?tableName=users&email=$emailForAuth'),
        headers: _authHeaders(accessToken),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          final completeUserData = data[0] as Map<String, dynamic>;

          if (kDebugMode) {
            debugPrint(
                '[AUTH] Usuario encontrado: ${completeUserData['email']} (${completeUserData['first_name']} ${completeUserData['last_name']})');
          }

          debugPrint(
              '[AUTH] Autenticación completada exitosamente para: ${completeUserData['email']}');

          return {
            'success': true,
            'accessToken': accessToken, // usar token real de ROBLE
            'refreshToken': authResponse['refreshToken'],
            'access_token': accessToken,
            'refresh_token': authResponse['refreshToken'],
            'data': completeUserData,
            'user': completeUserData,
          };
        } else {
          throw Exception('Usuario no encontrado en tabla users');
        }
      } else {
        throw Exception('Error buscando datos del usuario');
      }
    } catch (e) {
      debugPrint('[AUTH] Error en proceso de autenticación: $e');
      throw Exception('Credenciales inválidas');
    }
  }

  // Obtiene un token temporal para consultas públicas (p. ej., validación de disponibilidad)
  Future<String> _getTempAccessToken() async {
    try {
      // Usas valores en caché para evitar accesos repetidos al entorno
      _cachedReadonlyEmail ??= _env('ROBLE_READONLY_EMAIL');
      _cachedReadonlyPassword ??= _env('ROBLE_READONLY_PASSWORD');

      if (_cachedReadonlyEmail == null || _cachedReadonlyPassword == null) {
        throw Exception(
            'Faltan ROBLE_READONLY_EMAIL o ROBLE_READONLY_PASSWORD en .env');
      }
      final auth = await loginAuth(
        email: _cachedReadonlyEmail!,
        password: _cachedReadonlyPassword!,
      );
      final token = auth['accessToken'];
      if (token == null) throw Exception('No se pudo obtener token temporal');
      return token;
    } catch (e) {
      throw Exception('Error obteniendo token temporal: $e');
    }
  }

  // Verifica si un email está disponible para registro
  // Retorna true => disponible, false => NO disponible (incluye cualquier fallo de validación)
  Future<bool> isEmailAvailable(String email) async {
    final normalized = email.trim().toLowerCase();
    final baseUrl = '$_baseDatabaseUrl/$_dbName/read';
    debugPrint('[EMAIL_CHECK] Verificando disponibilidad de email');
    if (kDebugMode) {
      debugPrint('[EMAIL_CHECK] DB: $_dbName');
      debugPrint('[EMAIL_CHECK] Auth URL: $_baseAuthUrl');
      debugPrint('[EMAIL_CHECK] DB URL: $_baseDatabaseUrl');
      debugPrint('[EMAIL_CHECK] Email normalizado: "$normalized"');
    }

    for (var attempt = 1; attempt <= 3; attempt++) {
      try {
        debugPrint(
            '[EMAIL_CHECK] Intento $attempt - Obteniendo token temporal para verificación');
        final token = await _getTempAccessToken();
        print(
            '[EMAIL_CHECK] Token temporal obtenido: ${token.isNotEmpty ? '[OK length=${token.length}]' : '[EMPTY]'}');

        final uri = Uri.parse('$baseUrl?tableName=users&email=$normalized');
        debugPrint('[EMAIL_CHECK] Intento $attempt - GET $uri');
        final response = await http.get(uri, headers: _authHeaders(token));
        debugPrint(
            '[EMAIL_CHECK] Intento $attempt - Status: ${response.statusCode}');
        if (kDebugMode && response.body.isNotEmpty) {
          final preview = response.body.length > 500
              ? response.body.substring(0, 500) + '...'
              : response.body;
          debugPrint('[EMAIL_CHECK] Intento $attempt - Body preview: $preview');
        } else if (kDebugMode) {
          debugPrint('[EMAIL_CHECK] Intento $attempt - Empty body');
        }

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is List) {
            final count = data.length;
            debugPrint(
                '[EMAIL_CHECK] Intento $attempt - Lista parseada con $count filas');
            // Si existe al menos un registro con ese email => NO disponible
            final available = count == 0;
            debugPrint(
                '[EMAIL_CHECK] Intento $attempt - Email disponible: $available');
            return available;
          } else {
            debugPrint(
                '[EMAIL_CHECK] Intento $attempt - Tipo de payload inesperado: ${data.runtimeType}');
          }
        } else if (response.statusCode == 401 || response.statusCode == 403) {
          debugPrint(
              '[EMAIL_CHECK] Intento $attempt - No autorizado/Prohibido. Verifica credenciales de solo lectura/permisos para tabla "users".');
        } else {
          debugPrint(
              '[EMAIL_CHECK] Intento $attempt - Status inesperado: ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('[EMAIL_CHECK] Intento $attempt - Excepción: $e');
      }

      // Pequeño backoff entre intentos
      await Future.delayed(const Duration(milliseconds: 200));
    }

    debugPrint(
        '[EMAIL_CHECK] Todos los intentos fallaron, retornando NO DISPONIBLE (fail-closed)');
    return false; // fail-closed: si no puedes validar, bloqueas registro para evitar colisiones
  }

  // Verifica si un username está disponible para registro
  // Retorna true => disponible, false => NO disponible (incluye cualquier fallo de validación)
  Future<bool> isUsernameAvailable(String username) async {
    final raw = username.trim();
    // Nota: por defecto Postgres compara con sensibilidad a mayúsculas/minúsculas.
    // Puedes normalizar si tu política es username en minúsculas, considera normalizar aquí y en DB.
    final candidate = raw; // o raw.toLowerCase() si se homologa en DB
    final baseUrl = '$_baseDatabaseUrl/$_dbName/read';
    debugPrint('[USERNAME_CHECK] Verificando disponibilidad de username');
    if (kDebugMode) {
      debugPrint('[USERNAME_CHECK] DB: $_dbName');
      debugPrint(
          '[USERNAME_CHECK] Username (raw): "$raw" -> (candidate): "$candidate"');
    }

    for (var attempt = 1; attempt <= 3; attempt++) {
      try {
        debugPrint(
            '[USERNAME_CHECK] Intento $attempt - Obteniendo token temporal para verificación');
        final token = await _getTempAccessToken();
        debugPrint(
            '[USERNAME_CHECK] Token temporal obtenido: ${token.isNotEmpty ? '[OK length=${token.length}]' : '[EMPTY]'}');

        final uri = Uri.parse('$baseUrl?tableName=users&username=$candidate');
        debugPrint('[USERNAME_CHECK] Intento $attempt - GET $uri');
        final response = await http.get(uri, headers: _authHeaders(token));
        debugPrint(
            '[USERNAME_CHECK] Intento $attempt - Status: ${response.statusCode}');
        if (kDebugMode && response.body.isNotEmpty) {
          final preview = response.body.length > 500
              ? response.body.substring(0, 500) + '...'
              : response.body;
          debugPrint(
              '[USERNAME_CHECK] Intento $attempt - Body preview: $preview');
        } else if (kDebugMode) {
          debugPrint('[USERNAME_CHECK] Intento $attempt - Empty body');
        }

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is List) {
            final count = data.length;
            debugPrint(
                '[USERNAME_CHECK] Intento $attempt - Lista parseada con $count filas');
            final available = count == 0;
            debugPrint(
                '[USERNAME_CHECK] Intento $attempt - Username disponible: $available');
            return available;
          } else {
            debugPrint(
                '[USERNAME_CHECK] Intento $attempt - Tipo de payload inesperado: ${data.runtimeType}');
          }
        } else if (response.statusCode == 401 || response.statusCode == 403) {
          debugPrint(
              '[USERNAME_CHECK] Intento $attempt - No autorizado/Prohibido. Verifica credenciales de solo lectura/permisos para tabla "users".');
        } else {
          debugPrint(
              '[USERNAME_CHECK] Intento $attempt - Status inesperado: ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('[USERNAME_CHECK] Intento $attempt - Excepción: $e');
      }

      await Future.delayed(const Duration(milliseconds: 200));
    }

    debugPrint(
        '[USERNAME_CHECK] Todos los intentos fallaron, retornando NO DISPONIBLE (fail-closed)');
    return false; // fail-closed
  }

  // Utilidad opcional: health check de conectividad y permisos
  Future<bool> robleHealthCheck() async {
    try {
      print('=== ROBLE Health Check ===');
      print('Auth URL: $_baseAuthUrl');
      print('DB URL: $_baseDatabaseUrl');
      print('DB Name: $_dbName');

      final roEmail = _env('ROBLE_READONLY_EMAIL');
      final roPassPresent = _env('ROBLE_READONLY_PASSWORD') != null;
      print('Readonly email present: ${roEmail != null}');
      print('Readonly password present: $roPassPresent');

      final token = await _getTempAccessToken();
      print('Temp token acquired (len=${token.length})');

      final uri =
          Uri.parse('$_baseDatabaseUrl/$_dbName/read?tableName=users&_limit=1');
      print('Checking DB read access: GET $uri');
      final resp = await http.get(uri, headers: _authHeaders(token));
      print('DB read status: ${resp.statusCode}');
      if (resp.body.isNotEmpty) {
        final preview = resp.body.length > 300
            ? resp.body.substring(0, 300) + '...'
            : resp.body;
        print('DB read body preview: $preview');
      }
      final ok = resp.statusCode == 200;
      print('Health check result: $ok');
      return ok;
    } catch (e) {
      print('Health check error: $e');
      return false;
    }
  }

  // login original usando el auth de ROBLE (solo para verificacion de email)
  Future<Map<String, dynamic>> loginAuth({
    required String email,
    required String password,
  }) async {
    try {
      final url = '$_baseAuthUrl/$_dbName/login';
      print('Login Auth - Intentando login en: $url');
      print('Login Auth - Email: $email');

      final response = await http.post(
        Uri.parse(url),
        headers: _baseHeaders,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('Login Auth - Response status: ${response.statusCode}');
      print('Login Auth - Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        // normalizo la respuesta para que el AuthController la entienda fácil
        return {
          'success': true,
          'accessToken': data['accessToken'],
          'refreshToken': data['refreshToken'],
          'access_token': data['accessToken'], // por compatibilidad
          'refresh_token': data['refreshToken'], // por compatibilidad
          'data': data['user'],
          'user': data['user'],
        };
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Error en login auth');
      }
    } catch (e) {
      print('Error en login auth: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  // verifico si el token sigue siendo válido
  Future<Map<String, dynamic>> verifyToken({
    required String accessToken,
  }) async {
    try {
      final url = '$_baseAuthUrl/$_dbName/verify-token';
      print('Verificando token en: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: _authHeaders(accessToken),
      );

      print('Verify-token status: ${response.statusCode}');
      print('Verify-token body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is Map<String, dynamic>
            ? data
            : {'valid': true, 'data': data};
      } else {
        return {'valid': false};
      }
    } catch (e) {
      print('Error verificando token: $e');
      return {'valid': false, 'error': e.toString()};
    }
  }

  // registro inicial - solo manda email para verificación
  Future<Map<String, dynamic>> signup({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final url = '$_baseAuthUrl/$_dbName/signup';
      print('Intentando registro con verificación en: $url');
      print('Email: $email, Name: $name');

      final response = await http.post(
        Uri.parse(url),
        headers: _baseHeaders,
        body: jsonEncode({
          'email': email,
          'password': password,
          'name': name,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Error en registro');
      }
    } catch (e) {
      print('Error en registro: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  // verifico el código que llegó al email
  Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
  }) async {
    try {
      final url = '$_baseAuthUrl/$_dbName/verify-email';
      print('Verificando email en: $url');
      print('Email: $email, Code: $code');

      final response = await http.post(
        Uri.parse(url),
        headers: _baseHeaders,
        body: jsonEncode({
          'email': email,
          'code': code,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        // ROBLE responde con mensaje de éxito pero no con 'success' field
        // le agrego 'success': true para manejarlo más fácil
        if (response.statusCode == 201 && data.containsKey('message')) {
          data['success'] = true;
        }
        return data;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Código de verificación inválido');
      }
    } catch (e) {
      print('Error verificando email: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  // registro directo sin verificación de email (no lo uso pero está por si acaso)
  Future<Map<String, dynamic>> signupDirect({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final url = '$_baseAuthUrl/$_dbName/signup-direct';
      print('Intentando registro directo en: $url');
      print('Email: $email, Name: $name');

      final response = await http.post(
        Uri.parse(url),
        headers: _baseHeaders,
        body: jsonEncode({
          'email': email,
          'password': password,
          'name': name,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Error en registro');
      }
    } catch (e) {
      print('Error en registro: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  // ========== RECUPERACIÓN DE CONTRASEÑA ==========

  // Flujo completo para "olvidaste tu contraseña":
  //
  // PASO 1: requestPasswordReset(email)
  // - Envía email con enlace de ROBLE
  //
  // PASO 2: Usuario sigue estas instrucciones:
  // "1. Revisa tu correo electrónico
  //  2. Haz clic en el botón 'Restablecer Contraseña'
  //  3. Se abrirá una página web - COPIA la dirección completa que aparece arriba
  //  4. Regresa a la app y pega esa dirección en el campo"
  //
  // PASO 3: extractTokenFromResetUrl(url)
  // - Extrae el token de la URL pegada por el usuario
  // - Valida que sea una URL válida de ROBLE
  //
  // PASO 4: validateResetToken(token)
  // - Verifica que el token sea válido y no haya expirado
  //
  // PASO 5: resetPassword(token, newPassword)
  // - Cambia la contraseña en AUTH de ROBLE
  //
  // EXPIRACIÓN: 15 minutos desde que se envía el email
  //
  // UI SUGERIDA:
  // Screen 1: Campo email -> botón "Enviar enlace"
  // Screen 2: Instrucciones + campo para pegar URL -> botón "Validar"
  // Screen 3: Campos "Nueva contraseña" y "Confirmar" -> botón "Cambiar"
  // Screen 4: Confirmación de cambio exitoso  // paso 1: solicitar código de recuperación por email
  Future<Map<String, dynamic>> requestPasswordReset({
    required String email,
  }) async {
    try {
      final url = '$_baseAuthUrl/$_dbName/forgot-password';
      print('Solicitando reset de contraseña en: $url');
      print('Email: $email');

      final response = await http.post(
        Uri.parse(url),
        headers: _baseHeaders,
        body: jsonEncode({
          'email': email,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message':
              data['message'] ?? 'Código de recuperación enviado al email',
          'data': data,
        };
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Error solicitando reset');
      }
    } catch (e) {
      print('Error solicitando reset: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  // Función de prueba para el sistema de recuperación de contraseña
  Future<void> testForgotPassword() async {
    try {
      debugPrint(
          '[PASSWORD_RESET] Iniciando prueba de recuperación de contraseña');
      final result = await requestPasswordReset(email: 'caleones4@gmail.com');
      debugPrint('[PASSWORD_RESET] Resultado: $result');
    } catch (e) {
      debugPrint('[PASSWORD_RESET] Error en prueba: $e');
    }
  }

  // Ejecuta el flujo completo de restablecimiento de contraseña
  Future<Map<String, dynamic>> completePasswordReset({
    required String resetUrl,
    required String newPassword,
  }) async {
    try {
      debugPrint(
          '[PASSWORD_RESET] Iniciando flujo completo de restablecimiento');

      // Paso 1: Extraes el token de la URL
      print('Extrayendo token de la URL...');
      final token = extractTokenFromResetUrl(resetUrl);
      if (token == null) {
        throw Exception(
            'URL inválida. Asegúrate de copiar el enlace completo del email.');
      }

      // Paso 2: Validar que el token sea válido
      print('Validando token...');
      final isValidToken = await validateResetToken(token);
      if (!isValidToken) {
        throw Exception(
            'El enlace ha expirado o es inválido. Solicita un nuevo enlace.');
      }

      // Paso 3: Cambiar la contraseña
      print('Cambiando contraseña...');
      final result =
          await resetPassword(token: token, newPassword: newPassword);

      debugPrint('[PASSWORD_RESET] Restablecimiento completado exitosamente');
      return result;
    } catch (e) {
      debugPrint('[PASSWORD_RESET] Error en flujo completo: $e');
      rethrow;
    }
  }

  // Extrae el token de restablecimiento de la URL del email
  String? extractTokenFromResetUrl(String url) {
    try {
      debugPrint('[PASSWORD_RESET] Extrayendo token de URL: $url');

      // Validas que sea una URL válida
      final uri = Uri.tryParse(url);
      if (uri == null) {
        debugPrint('[PASSWORD_RESET] URL inválida');
        return null;
      }

      // Validar que sea una URL de ROBLE reset-password
      if (!uri.host.contains('roble.openlab.uninorte.edu.co') ||
          !uri.path.contains('reset-password')) {
        print('URL no es de reset-password de ROBLE');
        return null;
      }

      // Extraer el token del parámetro query
      final token = uri.queryParameters['token'];
      if (token == null || token.isEmpty) {
        print('No se encontró token en la URL');
        return null;
      }

      print('Token extraído exitosamente: ${token.substring(0, 20)}...');
      return token;
    } catch (e) {
      print('Error extrayendo token: $e');
      return null;
    }
  }

  // Valida si un token de restablecimiento es válido (sin cambiar contraseña)
  Future<bool> validateResetToken(String token) async {
    try {
      debugPrint('[PASSWORD_RESET] Validando token de restablecimiento');

      // Intentas hacer una petición de reset con una contraseña temporal
      // Si el token es válido, recibirás un error específico o éxito
      final url = '$_baseAuthUrl/$_dbName/reset-password';
      final response = await http.post(
        Uri.parse(url),
        headers: _baseHeaders,
        body: jsonEncode({
          'token': token,
          'newPassword': '', // contraseña vacía para solo validar token
        }),
      );

      print('Validación token status: ${response.statusCode}');
      print('Validación token body: ${response.body}');

      // Si el token es válido pero la contraseña es inválida,
      // deberíamos recibir un error sobre la contraseña, no sobre el token
      if (response.statusCode == 400) {
        final error = jsonDecode(response.body);
        final message = error['message'] ?? '';

        // Si el error es sobre la contraseña, el token es válido
        if (message.toLowerCase().contains('password') ||
            message.toLowerCase().contains('contraseña')) {
          print('Token válido (error de contraseña como esperado)');
          return true;
        }

        // Si el error es sobre el token, entonces el token es inválido
        if (message.toLowerCase().contains('token') ||
            message.toLowerCase().contains('invalid') ||
            message.toLowerCase().contains('expired')) {
          print('Token inválido o expirado');
          return false;
        }
      }

      // Si es 200, el token también es válido (aunque la contraseña vacía funcionó)
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Token válido');
        return true;
      }

      print('Token inválido');
      return false;
    } catch (e) {
      print('Error validando token: $e');
      return false;
    }
  }

  // paso 2: cambiar contraseña con token de reset
  Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      debugPrint('[PASSWORD_RESET] Iniciando restablecimiento de contraseña');
      if (kDebugMode) {
        debugPrint(
            '[PASSWORD_RESET] Token: ${token.isNotEmpty ? "[PRESENTE]" : "[VACÍO]"}');
        debugPrint(
            '[PASSWORD_RESET] Nueva contraseña: ${newPassword.isNotEmpty ? "[PRESENTE]" : "[VACÍO]"}');
      }

      final url = '$_baseAuthUrl/$_dbName/reset-password';
      final response = await http.post(
        Uri.parse(url),
        headers: _baseHeaders,
        body: jsonEncode({
          'token': token,
          'newPassword': newPassword,
        }),
      );

      debugPrint(
          '[PASSWORD_RESET] Status de respuesta: ${response.statusCode}');
      print('Reset response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('=== RESET DE CONTRASEÑA COMPLETADO ===');

        return {
          'success': true,
          'message': 'Contraseña cambiada exitosamente',
          'data': data,
        };
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Error cambiando contraseña');
      }
    } catch (e) {
      print('Error en reset de contraseña: $e');
      throw Exception('Error cambiando contraseña: $e');
    }
  }

  // ========== MI BASE DE DATOS ==========

  // creo el usuario en mi tabla de users después del registro
  Future<Map<String, dynamic>> createUserInDatabase({
    required String accessToken,
    required String email,
    required String firstName,
    required String lastName,
    required String username,
    String? studentId,
  }) async {
    try {
      final url = '$_baseDatabaseUrl/$_dbName/insert';
      print('Creando usuario en database: $url');
      print('Email: $email, Username: $username');

      final response = await http.post(
        Uri.parse(url),
        headers: _authHeaders(accessToken),
        body: jsonEncode({
          'tableName': 'users',
          'records': [
            {
              'email': email,
              'first_name': firstName,
              'last_name': lastName,
              'username': username,
              'student_id': studentId ?? '',
              'is_active': true,
              'created_at': DateTime.now().toIso8601String(),
            }
          ]
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        // si el insert no insertó nada y solo dice "skipped", es un error
        if (data is Map<String, dynamic>) {
          final inserted = data['inserted'];
          final skipped = data['skipped'];
          if (inserted is List && inserted.isNotEmpty) {
            return data;
          }
          String reason = 'Insert no realizó ninguna inserción';
          if (skipped is List && skipped.isNotEmpty) {
            final r = skipped
                .map((e) => e is Map ? e['reason'] : null)
                .whereType<String>()
                .join(' | ');
            if (r.isNotEmpty) reason = r;
          }
          throw Exception(reason);
        }
        return data;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(
            error['message'] ?? 'Error creando usuario en database');
      }
    } catch (e) {
      print('Error creando usuario en database: $e');
      throw Exception('Error creando usuario en database: $e');
    }
  }

  // Obtiene el perfil del usuario (implementación temporal)
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      // TODO: cuando ROBLE tenga endpoint de perfil lo conectas acá
      // Por ahora retornas datos temporales
      return {
        'success': true,
        'data': {
          'id': 'temp_user_id',
          'email': 'temp@example.com',
          'firstName': 'Usuario',
          'lastName': 'Temporal',
          'username': 'temp_user',
          'created_at': DateTime.now().toIso8601String(),
        }
      };
    } catch (e) {
      debugPrint('[PROFILE] Error obteniendo perfil de usuario: $e');
      return {
        'success': false,
        'message': 'Error obteniendo perfil: $e',
      };
    }
  }

  // Busca un usuario en la tabla users por email
  Future<Map<String, dynamic>?> getUserFromDatabase({
    required String accessToken,
    required String email,
  }) async {
    try {
      debugPrint('[DB_USER] Buscando usuario en base de datos');
      debugPrint('[DB_USER] Email: $email');
      if (kDebugMode) {
        debugPrint(
            '[DB_USER] Token: ${accessToken.isNotEmpty ? "[PRESENTE]" : "[VACÍO]"}');
      }

      final url = '$_baseDatabaseUrl/$_dbName/read';

      final response = await http.get(
        Uri.parse('$url?tableName=users&email=$email'),
        headers: _authHeaders(accessToken),
      );

      debugPrint('[DB_USER] Status de respuesta: ${response.statusCode}');
      if (kDebugMode) {
        debugPrint('[DB_USER] Cuerpo de respuesta: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          final userData = data[0] as Map<String, dynamic>;
          debugPrint('[DB_USER] Usuario encontrado: ${userData['email']}');
          return userData;
        } else {
          debugPrint('[DB_USER] No se encontraron usuarios con ese email');
        }
      } else {
        debugPrint(
            '[DB_USER] Error en consulta a base de datos: ${response.statusCode}');
      }
      return null;
    } catch (e) {
      debugPrint('[DB_USER] Error buscando usuario en database: $e');
      return null;
    }
  }
}
