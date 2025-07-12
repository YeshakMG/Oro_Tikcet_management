import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:oro_ticket_app/data/locals/models/departure_terminal_model.dart';
import 'package:oro_ticket_app/data/locals/service/departure_terminal_storage_service.dart';
import 'package:oro_ticket_app/data/repositories/sync_repository.dart';
import '../models/user_model.dart';

class AuthService {
  static final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';
  final SyncRepository syncRepo = Get.put(SyncRepository());

  final String baseUrl = dotenv.env['API_BASE_URL'] ?? '';

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/auth/company-user/login');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['status'] == 'success') {
      final token = data['data']['token'];
      final user = UserModel.fromJson(data['data']['user']);

      await _storage.write(key: _tokenKey, value: token);
      await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
      try {
        await syncRepo.syncCommissionRules();
        print('✅ Commission rules synced after login.');
      } catch (e) {
        print('❌ Failed to sync commission rules after login: $e');
      }
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

  Future<void> fetchAndStoreProfileData() async {
    final token = await getToken();
    if (token == null) return;

    final url = Uri.parse('$baseUrl/auth/company-user/profile');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final terminalJson = data['data']['terminal'];

      if (terminalJson != null) {
        final terminal = DepartureTerminalModel.fromJson(terminalJson);
        await DepartureTerminalStorageService.saveTerminal(terminal);
      }
    } else {
      throw Exception('Failed to fetch profile data');
    }
  }
}
