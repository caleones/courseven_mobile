import 'dart:convert';
import 'package:http/http.dart' as http;

// servicio que maneja toda la comunicación con ROBLE
class RobleService {
  static const String _baseAuthUrl =
      'https://roble-api.openlab.uninorte.edu.co/auth';
  static const String _baseDatabaseUrl =
      'https://roble-api.openlab.uninorte.edu.co/database';
  static const String _dbName = 'courseven_66a52df881';

  // headers básicos para todas las peticiones
  Map<String, String> get _baseHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // headers cuando necesito mandar el token
  Map<String, String> _authHeaders(String token) => {
        ..._baseHeaders,
        'Authorization': 'Bearer $token',
      };

  // ========== AUTENTICACIÓN ==========

  // login con email y contraseña
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final url = '$_baseAuthUrl/$_dbName/login';
      print('Intentando login en: $url');
      print('Email: $email');

      final response = await http.post(
        Uri.parse(url),
        headers: _baseHeaders,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

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
        throw Exception(error['message'] ?? 'Error en login');
      }
    } catch (e) {
      print('Error en login: $e');
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

  // ========== MI BASE DE DATOS ==========

  // creo el usuario en mi tabla de users después del registro
  Future<Map<String, dynamic>> createUserInDatabase({
    required String accessToken,
    required String email,
    required String firstName,
    required String lastName,
    required String username,
    required String password,
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
              'key_password': password,
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

  // perfil del usuario - por ahora mock
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      // TODO: cuando ROBLE tenga endpoint de perfil lo conecto acá
      // por ahora devuelvo datos temporales
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
      print('Error obteniendo perfil de usuario: $e');
      return {
        'success': false,
        'message': 'Error obteniendo perfil: $e',
      };
    }
  }

  // busco un usuario en mi tabla de users por email
  Future<Map<String, dynamic>?> getUserFromDatabase({
    required String accessToken,
    required String email,
  }) async {
    try {
      final url = '$_baseDatabaseUrl/$_dbName/read';
      print('Buscando usuario en database: $url');
      print('Email: $email');

      final response = await http.get(
        Uri.parse('$url?tableName=users&email=$email'),
        headers: _authHeaders(accessToken),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          return data[0];
        }
        return null;
      } else {
        return null;
      }
    } catch (e) {
      print('Error buscando usuario en database: $e');
      return null;
    }
  }
}
