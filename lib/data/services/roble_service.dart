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
    if (_cachedDbUrl == null) {
      // Prefer env var but fall back to default
      var raw = _env('ROBLE_DB_BASE_URL') ?? _fallbackDbUrl;
      var normalized = raw.trim();
      // Remove trailing slashes
      while (normalized.endsWith('/')) {
        normalized = normalized.substring(0, normalized.length - 1);
      }
      // Ensure the base URL points to the /database endpoint exactly
      // Common misconfig: env contains host without '/database' which would cause
      // requests like '/<dbName>/update' (404). We fix it here.
      const seg = '/database';
      if (!normalized.endsWith(seg)) {
        final idx = normalized.indexOf(seg);
        if (idx >= 0) {
          // Trim to include only up to '/database'
          normalized = normalized.substring(0, idx + seg.length);
        } else {
          normalized = '$normalized$seg';
        }
      }
      _cachedDbUrl = normalized;
      debugPrint('[ROBLE] DB base URL normalized to: $_cachedDbUrl');
    }
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

  // ========== CURSOS (Database) ==========

  Uri _dbReadUri(String table, [Map<String, String>? query]) {
    final params = {'tableName': table, ...?query};
    return Uri.parse('$_baseDatabaseUrl/$_dbName/read')
        .replace(queryParameters: params);
  }

  /// Lee cursos por ID de profesor (teacher_id)
  Future<List<Map<String, dynamic>>> readCoursesByTeacher({
    required String accessToken,
    required String teacherId,
    int? limit,
  }) async {
    try {
      final qp = {
        'teacher_id': teacherId,
        if (limit != null) '_limit': '$limit',
      };
      final uri = _dbReadUri('courses', qp);
      final resp = await http.get(uri, headers: _authHeaders(accessToken));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        }
        return const [];
      }
      throw Exception('DB read courses failed: ${resp.statusCode}');
    } catch (e) {
      debugPrint('[COURSES] Error leyendo cursos por teacher: $e');
      rethrow;
    }
  }

  /// Inserta un curso en la tabla courses
  Future<Map<String, dynamic>> insertCourse({
    required String accessToken,
    required Map<String, dynamic> record,
  }) async {
    try {
      final url = '$_baseDatabaseUrl/$_dbName/insert';
      final resp = await http.post(
        Uri.parse(url),
        headers: _authHeaders(accessToken),
        body: jsonEncode({
          'tableName': 'courses',
          'records': [record],
        }),
      );
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final data = jsonDecode(resp.body);
        return data is Map<String, dynamic> ? data : {'data': data};
      }
      final err = resp.body.isNotEmpty ? resp.body : 'unknown error';
      throw Exception('DB insert course failed: ${resp.statusCode} $err');
    } catch (e) {
      debugPrint('[COURSES] Error insertando curso: $e');
      rethrow;
    }
  }

  /// Actualiza un curso (por _id)
  Future<Map<String, dynamic>> updateCourse({
    required String accessToken,
    required String id,
    required Map<String, dynamic> updates,
  }) async {
    try {
      final baseUrl = _baseDatabaseUrl; // triggers normalization + log
      final primaryUrl = '$baseUrl/$_dbName/update';
      final payload = {
        'tableName': 'courses',
        'idColumn': '_id',
        'idValue': id,
        'updates': updates,
      };
      // Verbose logging for diagnostics
      debugPrint('[COURSES][UPDATE] ====== BEGIN REQUEST ======');
      debugPrint('[COURSES][UPDATE] DB Base URL: $baseUrl');
      debugPrint('[COURSES][UPDATE] DB Name    : $_dbName');
      debugPrint('[COURSES][UPDATE] Target URL : $primaryUrl');
      debugPrint('[COURSES][UPDATE] Payload    : ${jsonEncode(payload)}');
      debugPrint(
          '[COURSES][UPDATE] AccessTok? : ${accessToken.isNotEmpty} length=${accessToken.length}');
      final startedAt = DateTime.now();
      final resp = await http.put(
        Uri.parse(primaryUrl),
        headers: _authHeaders(accessToken),
        body: jsonEncode(payload),
      );
      final elapsed = DateTime.now().difference(startedAt).inMilliseconds;
      debugPrint(
          '[COURSES][UPDATE] Status      : ${resp.statusCode} (${elapsed}ms)');
      if (resp.body.isNotEmpty) {
        final prev = resp.body.length > 400
            ? resp.body.substring(0, 400) + '...'
            : resp.body;
        debugPrint('[COURSES][UPDATE] Body preview: $prev');
      } else {
        debugPrint('[COURSES][UPDATE] Empty body response');
      }

      // Success path
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        debugPrint('[COURSES][UPDATE] SUCCESS primary endpoint');
        final data = jsonDecode(resp.body);
        debugPrint('[COURSES][UPDATE] Parsed type: ${data.runtimeType}');
        debugPrint('[COURSES][UPDATE] ====== END REQUEST (SUCCESS) ======');
        return data is Map<String, dynamic> ? data : {'data': data};
      }

      // If 404, attempt a fallback assumption: maybe env already included '/database' and we added again? (defensive)
      if (resp.statusCode == 404) {
        // Derive an alternate base by stripping a trailing '/database'
        String altBase = baseUrl.endsWith('/database')
            ? baseUrl.substring(0, baseUrl.length - '/database'.length)
            : baseUrl;
        // Also try without re-appending '/database'
        final altUrl = '$altBase/$_dbName/update';
        if (altUrl != primaryUrl) {
          debugPrint(
              '[COURSES][UPDATE] 404 detected. Trying fallback URL: $altUrl');
          final resp2 = await http.put(
            Uri.parse(altUrl),
            headers: _authHeaders(accessToken),
            body: jsonEncode(payload),
          );
          debugPrint('[COURSES][UPDATE] Fallback status: ${resp2.statusCode}');
          if (resp2.body.isNotEmpty) {
            final prev2 = resp2.body.length > 400
                ? resp2.body.substring(0, 400) + '...'
                : resp2.body;
            debugPrint('[COURSES][UPDATE] Fallback body preview: $prev2');
          }
          if (resp2.statusCode == 200 || resp2.statusCode == 201) {
            debugPrint('[COURSES][UPDATE] SUCCESS fallback endpoint');
            final data = jsonDecode(resp2.body);
            debugPrint(
                '[COURSES][UPDATE] ====== END REQUEST (SUCCESS-FALLBACK) ======');
            return data is Map<String, dynamic> ? data : {'data': data};
          }
        } else {
          debugPrint(
              '[COURSES][UPDATE] Fallback URL identical; skipping retry');
        }
      }

      final err = resp.body.isNotEmpty ? resp.body : 'unknown error';
      debugPrint('[COURSES][UPDATE] FAILURE: ${resp.statusCode} $err');
      debugPrint('[COURSES][UPDATE] ====== END REQUEST (FAILURE) ======');
      throw Exception('DB update course failed: ${resp.statusCode} $err');
    } catch (e) {
      debugPrint('[COURSES] Error actualizando curso: $e');
      rethrow;
    }
  }

  /// Lee cursos con consulta arbitraria (por id, categoría, etc.)
  Future<List<Map<String, dynamic>>> readCourses({
    required String accessToken,
    Map<String, String>? query,
  }) async {
    try {
      final uri = _dbReadUri('courses', query);
      final resp = await http.get(uri, headers: _authHeaders(accessToken));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data is List) return data.cast<Map<String, dynamic>>();
        return const [];
      }
      throw Exception('DB read courses failed: ${resp.statusCode}');
    } catch (e) {
      debugPrint('[COURSES] Error leyendo cursos: $e');
      rethrow;
    }
  }

  /// Busca cursos por join_code exacto
  Future<List<Map<String, dynamic>>> readCoursesByJoinCode({
    required String accessToken,
    required String joinCode,
  }) async {
    return readCourses(
        accessToken: accessToken, query: {'join_code': joinCode});
  }

  // ========== CATEGORÍAS (Database) ==========

  /// Lee categorías con filtros
  Future<List<Map<String, dynamic>>> readCategories({
    required String accessToken,
    Map<String, String>? query,
  }) async {
    try {
      final uri = _dbReadUri('categories', query);
      final resp = await http.get(uri, headers: _authHeaders(accessToken));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data is List) return data.cast<Map<String, dynamic>>();
        return const [];
      }
      throw Exception('DB read categories failed: ${resp.statusCode}');
    } catch (e) {
      debugPrint('[CATEGORIES] Error leyendo categorías: $e');
      rethrow;
    }
  }

  /// Inserta una categoría en la tabla categories
  Future<Map<String, dynamic>> insertCategory({
    required String accessToken,
    required Map<String, dynamic> record,
  }) async {
    try {
      final url = '$_baseDatabaseUrl/$_dbName/insert';
      final resp = await http.post(
        Uri.parse(url),
        headers: _authHeaders(accessToken),
        body: jsonEncode({
          'tableName': 'categories',
          'records': [record],
        }),
      );
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final data = jsonDecode(resp.body);
        return data is Map<String, dynamic> ? data : {'data': data};
      }
      final err = resp.body.isNotEmpty ? resp.body : 'unknown error';
      throw Exception('DB insert category failed: ${resp.statusCode} $err');
    } catch (e) {
      debugPrint('[CATEGORIES] Error insertando categoría: $e');
      rethrow;
    }
  }

  /// Actualiza una categoría (por _id)
  Future<Map<String, dynamic>> updateCategory({
    required String accessToken,
    required String id,
    required Map<String, dynamic> updates,
  }) async {
    try {
      final url = '$_baseDatabaseUrl/$_dbName/update';
      final payload = {
        'tableName': 'categories',
        'filter': {'_id': id},
        'updates': updates,
      };
      final resp = await http.post(
        Uri.parse(url),
        headers: _authHeaders(accessToken),
        body: jsonEncode(payload),
      );
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final data = jsonDecode(resp.body);
        return data is Map<String, dynamic> ? data : {'data': data};
      }
      final err = resp.body.isNotEmpty ? resp.body : 'unknown error';
      throw Exception('DB update category failed: ${resp.statusCode} $err');
    } catch (e) {
      debugPrint('[CATEGORIES] Error actualizando categoría: $e');
      rethrow;
    }
  }

  // ========== GRUPOS (Database) ==========

  /// Lee grupos con filtros
  Future<List<Map<String, dynamic>>> readGroups({
    required String accessToken,
    Map<String, String>? query,
  }) async {
    try {
      final uri = _dbReadUri('groups', query);
      final resp = await http.get(uri, headers: _authHeaders(accessToken));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data is List) return data.cast<Map<String, dynamic>>();
        return const [];
      }
      throw Exception('DB read groups failed: ${resp.statusCode}');
    } catch (e) {
      debugPrint('[GROUPS] Error leyendo grupos: $e');
      rethrow;
    }
  }

  /// Inserta un grupo en la tabla groups
  Future<Map<String, dynamic>> insertGroup({
    required String accessToken,
    required Map<String, dynamic> record,
  }) async {
    try {
      final url = '$_baseDatabaseUrl/$_dbName/insert';
      final resp = await http.post(
        Uri.parse(url),
        headers: _authHeaders(accessToken),
        body: jsonEncode({
          'tableName': 'groups',
          'records': [record],
        }),
      );
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final data = jsonDecode(resp.body);
        return data is Map<String, dynamic> ? data : {'data': data};
      }
      final err = resp.body.isNotEmpty ? resp.body : 'unknown error';
      throw Exception('DB insert group failed: ${resp.statusCode} $err');
    } catch (e) {
      debugPrint('[GROUPS] Error insertando grupo: $e');
      rethrow;
    }
  }

  /// Actualiza un grupo (por _id)
  Future<Map<String, dynamic>> updateGroup({
    required String accessToken,
    required String id,
    required Map<String, dynamic> updates,
  }) async {
    try {
      final url = '$_baseDatabaseUrl/$_dbName/update';
      final payload = {
        'tableName': 'groups',
        'filter': {'_id': id},
        'updates': updates,
      };
      final resp = await http.post(
        Uri.parse(url),
        headers: _authHeaders(accessToken),
        body: jsonEncode(payload),
      );
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final data = jsonDecode(resp.body);
        return data is Map<String, dynamic> ? data : {'data': data};
      }
      final err = resp.body.isNotEmpty ? resp.body : 'unknown error';
      throw Exception('DB update group failed: ${resp.statusCode} $err');
    } catch (e) {
      debugPrint('[GROUPS] Error actualizando grupo: $e');
      rethrow;
    }
  }

  // ========== ENROLLMENTS (Database) ==========

  /// Lee inscripciones con filtros
  Future<List<Map<String, dynamic>>> readEnrollments({
    required String accessToken,
    Map<String, String>? query,
  }) async {
    try {
      final uri = _dbReadUri('enrollments', query);
      final resp = await http.get(uri, headers: _authHeaders(accessToken));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data is List) return data.cast<Map<String, dynamic>>();
        return const [];
      } else if (resp.statusCode == 401) {
        throw Exception('Token de acceso expirado o inválido (401)');
      } else if (resp.statusCode == 403) {
        throw Exception('Acceso denegado para leer inscripciones (403)');
      }
      throw Exception('DB read enrollments failed: ${resp.statusCode}');
    } catch (e) {
      debugPrint('[ENROLLMENTS] Error leyendo inscripciones: $e');
      rethrow;
    }
  }

  // ========== ACTIVITIES (Database) ==========

  /// Lee actividades con filtros (por course_id, category_id, etc.)
  Future<List<Map<String, dynamic>>> readActivities({
    required String accessToken,
    Map<String, String>? query,
  }) async {
    try {
      final uri = _dbReadUri('activities', query);
      debugPrint('[ACTIVITIES][READ] GET $uri');
      final resp = await http.get(uri, headers: _authHeaders(accessToken));
      debugPrint('[ACTIVITIES][READ] Status: ${resp.statusCode}');
      if (kDebugMode) {
        final body = resp.body;
        final preview =
            body.length > 400 ? body.substring(0, 400) + '...' : body;
        debugPrint('[ACTIVITIES][READ] Body: $preview');
      }
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data is List) return data.cast<Map<String, dynamic>>();
        return const [];
      }
      throw Exception('DB read activities failed: ${resp.statusCode}');
    } catch (e) {
      debugPrint('[ACTIVITIES] Error leyendo actividades: $e');
      rethrow;
    }
  }

  /// Inserta una actividad en la tabla activities
  Future<Map<String, dynamic>> insertActivity({
    required String accessToken,
    required Map<String, dynamic> record,
  }) async {
    try {
      final url = '$_baseDatabaseUrl/$_dbName/insert';
      final payload = {
        'tableName': 'activities',
        'records': [record],
      };
      debugPrint('[ACTIVITIES][INSERT] POST $url');
      if (kDebugMode)
        debugPrint('[ACTIVITIES][INSERT] Payload: ${jsonEncode(payload)}');
      final resp = await http.post(
        Uri.parse(url),
        headers: _authHeaders(accessToken),
        body: jsonEncode(payload),
      );
      debugPrint('[ACTIVITIES][INSERT] Status: ${resp.statusCode}');
      if (kDebugMode) {
        final body = resp.body;
        final preview =
            body.length > 600 ? body.substring(0, 600) + '...' : body;
        debugPrint('[ACTIVITIES][INSERT] Body: $preview');
      }
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final data = jsonDecode(resp.body);
        return data is Map<String, dynamic> ? data : {'data': data};
      }
      final err = resp.body.isNotEmpty ? resp.body : 'unknown error';
      throw Exception('DB insert activity failed: ${resp.statusCode} $err');
    } catch (e) {
      debugPrint('[ACTIVITIES] Error insertando actividad: $e');
      rethrow;
    }
  }

  /// Actualiza una actividad (por _id)
  Future<Map<String, dynamic>> updateActivity({
    required String accessToken,
    required String id,
    required Map<String, dynamic> updates,
  }) async {
    try {
      final url = '$_baseDatabaseUrl/$_dbName/update';
      final payload = {
        'tableName': 'activities',
        'filter': {'_id': id},
        'updates': updates,
      };
      debugPrint('[ACTIVITIES][UPDATE] POST $url');
      if (kDebugMode) {
        debugPrint('[ACTIVITIES][UPDATE] Payload: ${jsonEncode(payload)}');
      }
      final resp = await http.post(
        Uri.parse(url),
        headers: _authHeaders(accessToken),
        body: jsonEncode(payload),
      );
      debugPrint('[ACTIVITIES][UPDATE] Status: ${resp.statusCode}');
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final data = jsonDecode(resp.body);
        return data is Map<String, dynamic> ? data : {'data': data};
      }
      final err = resp.body.isNotEmpty ? resp.body : 'unknown error';
      throw Exception('DB update activity failed: ${resp.statusCode} $err');
    } catch (e) {
      debugPrint('[ACTIVITIES] Error actualizando actividad: $e');
      rethrow;
    }
  }

  // ========== MEMBERSHIPS (Database) ==========

  /// Lee membresías con filtros
  Future<List<Map<String, dynamic>>> readMemberships({
    required String accessToken,
    Map<String, String>? query,
  }) async {
    try {
      final uri = _dbReadUri('memberships', query);
      debugPrint('[MEMBERSHIPS][READ] GET $uri');
      final resp = await http.get(uri, headers: _authHeaders(accessToken));
      debugPrint('[MEMBERSHIPS][READ] Status: ${resp.statusCode}');
      if (kDebugMode) {
        final body = resp.body;
        final preview =
            body.length > 400 ? body.substring(0, 400) + '...' : body;
        debugPrint('[MEMBERSHIPS][READ] Body: $preview');
      }
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data is List) return data.cast<Map<String, dynamic>>();
        return const [];
      }
      throw Exception('DB read memberships failed: ${resp.statusCode}');
    } catch (e) {
      debugPrint('[MEMBERSHIPS] Error leyendo membresías: $e');
      rethrow;
    }
  }

  // ========== GENERIC TABLE HELPERS (lightweight) ==========
  /// Generic read for arbitrary table using simple equality filters.
  Future<List<Map<String, dynamic>>> readTable({
    required String accessToken,
    required String table,
    Map<String, String>? query,
  }) async {
    try {
      final uri = _dbReadUri(table, query);
      debugPrint('[GENERIC][READ][$table] GET $uri');
      final resp = await http.get(uri, headers: _authHeaders(accessToken));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data is List) return data.cast<Map<String, dynamic>>();
        return const [];
      }
      throw Exception('DB read $table failed: ${resp.statusCode}');
    } catch (e) {
      debugPrint('[GENERIC][READ][$table] Error: $e');
      rethrow;
    }
  }

  /// Generic insert (multiple records) returning raw backend response.
  Future<Map<String, dynamic>> insertTable({
    required String accessToken,
    required String table,
    required List<Map<String, dynamic>> records,
  }) async {
    try {
      final url = '$_baseDatabaseUrl/$_dbName/insert';
      final payload = {'tableName': table, 'records': records};
      debugPrint('[GENERIC][INSERT][$table] POST $url');
      final resp = await http.post(Uri.parse(url),
          headers: _authHeaders(accessToken), body: jsonEncode(payload));
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final data = jsonDecode(resp.body);
        return data is Map<String, dynamic> ? data : {'data': data};
      }
      throw Exception('DB insert $table failed: ${resp.statusCode}');
    } catch (e) {
      debugPrint('[GENERIC][INSERT][$table] Error: $e');
      rethrow;
    }
  }

  /// Generic update (filter by _id single) for arbitrary table.
  Future<Map<String, dynamic>> updateRow({
    required String accessToken,
    required String table,
    required String id,
    required Map<String, dynamic> updates,
  }) async {
    try {
      final url = '$_baseDatabaseUrl/$_dbName/update';
      final payload = {
        'tableName': table,
        'filter': {'_id': id},
        'updates': updates,
      };
      debugPrint('[GENERIC][UPDATE][$table] POST $url');
      if (kDebugMode)
        debugPrint('[GENERIC][UPDATE][$table] Payload: ' + jsonEncode(payload));
      final resp = await http.post(Uri.parse(url),
          headers: _authHeaders(accessToken), body: jsonEncode(payload));
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final data = jsonDecode(resp.body);
        return data is Map<String, dynamic> ? data : {'data': data};
      }
      final err = resp.body.isNotEmpty ? resp.body : 'unknown error';
      throw Exception('DB update $table failed: ${resp.statusCode} $err');
    } catch (e) {
      debugPrint('[GENERIC][UPDATE][$table] Error: $e');
      rethrow;
    }
  }

  /// Inserta una membresía en la tabla memberships
  Future<Map<String, dynamic>> insertMembership({
    required String accessToken,
    required Map<String, dynamic> record,
  }) async {
    try {
      final url = '$_baseDatabaseUrl/$_dbName/insert';
      final payload = {
        'tableName': 'memberships',
        'records': [record],
      };
      debugPrint('[MEMBERSHIPS][INSERT] POST $url');
      if (kDebugMode) {
        debugPrint('[MEMBERSHIPS][INSERT] Payload: ${jsonEncode(payload)}');
      }
      final resp = await http.post(
        Uri.parse(url),
        headers: _authHeaders(accessToken),
        body: jsonEncode(payload),
      );
      debugPrint('[MEMBERSHIPS][INSERT] Status: ${resp.statusCode}');
      if (kDebugMode) {
        final body = resp.body;
        final preview =
            body.length > 600 ? body.substring(0, 600) + '...' : body;
        debugPrint('[MEMBERSHIPS][INSERT] Body: $preview');
      }
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final data = jsonDecode(resp.body);
        return data is Map<String, dynamic> ? data : {'data': data};
      }
      final err = resp.body.isNotEmpty ? resp.body : 'unknown error';
      throw Exception('DB insert membership failed: ${resp.statusCode} $err');
    } catch (e) {
      debugPrint('[MEMBERSHIPS] Error insertando membresía: $e');
      rethrow;
    }
  }

  /// Inserta una inscripción en la tabla enrollments
  Future<Map<String, dynamic>> insertEnrollment({
    required String accessToken,
    required Map<String, dynamic> record,
  }) async {
    try {
      final url = '$_baseDatabaseUrl/$_dbName/insert';
      final resp = await http.post(
        Uri.parse(url),
        headers: _authHeaders(accessToken),
        body: jsonEncode({
          'tableName': 'enrollments',
          'records': [record],
        }),
      );
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final data = jsonDecode(resp.body);
        return data is Map<String, dynamic> ? data : {'data': data};
      }
      final err = resp.body.isNotEmpty ? resp.body : 'unknown error';
      throw Exception('DB insert enrollment failed: ${resp.statusCode} $err');
    } catch (e) {
      debugPrint('[ENROLLMENTS] Error insertando inscripción: $e');
      rethrow;
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
  /// Lee usuarios con filtros arbitrarios (por _id, email, username, etc.)
  Future<List<Map<String, dynamic>>> readUsers({
    required String accessToken,
    Map<String, String>? query,
  }) async {
    try {
      final uri = _dbReadUri('users', query);
      final resp = await http.get(uri, headers: _authHeaders(accessToken));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data is List) return data.cast<Map<String, dynamic>>();
        return const [];
      }
      throw Exception('DB read users failed: ${resp.statusCode}');
    } catch (e) {
      debugPrint('[USERS] Error leyendo usuarios: $e');
      rethrow;
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

  // Renueva el access token usando el refresh token
  Future<Map<String, dynamic>?> refreshAccessToken(String refreshToken) async {
    try {
      debugPrint('[ROBLE] Renovando access token...');

      final response = await http.post(
        Uri.parse('$_baseAuthUrl/refresh-token'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'refreshToken': refreshToken,
        }),
      );

      debugPrint('[ROBLE] Refresh token response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('[ROBLE] Token renovado exitosamente');
        return {
          'accessToken': data['accessToken'],
          'refreshToken': data['refreshToken'], // nuevo refresh token
        };
      } else {
        debugPrint(
            '[ROBLE] Error renovando token: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('[ROBLE] Excepción renovando token: $e');
      return null;
    }
  }
}
