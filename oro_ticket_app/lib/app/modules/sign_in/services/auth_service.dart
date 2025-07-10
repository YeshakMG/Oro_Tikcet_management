import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/user_model.dart';

class AuthService {
  static final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  final String baseUrl = dotenv.env['API_BASE_URL'] ?? '';


  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    // required String terminalId,
  }) async {
    final url = Uri.parse('$baseUrl/auth/login');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        // 'terminal_id': terminalId,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['status'] == 'success') {
      final token = data['data']['token'];
      final user = UserModel.fromJson(data['data']['user']);

      await _storage.write(key: _tokenKey, value: token);
      await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));

      return {'success': true, 'user': user, 'token': token};
    } else {
      return {
        'success': false,
        'message': data['message'] ?? 'Login failed',
        'errors': data['errors'] ?? []
      };
    }
  }

  Future<void> logout() async {
    final token = await _storage.read(key: _tokenKey);
    final url = Uri.parse('$baseUrl/auth/logout');

    await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }

  Future<String?> getToken() => _storage.read(key: _tokenKey);

  Future<UserModel?> getUser() async {
    final jsonString = await _storage.read(key: _userKey);
    if (jsonString != null) {
      final map = jsonDecode(jsonString);
      return UserModel.fromJson(Map<String, dynamic>.from(map));
    }
    return null;
  }

  Future<bool> isLoggedIn() async => (await getToken()) != null;
}
