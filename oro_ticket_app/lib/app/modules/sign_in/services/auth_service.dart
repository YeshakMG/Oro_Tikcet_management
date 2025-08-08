import 'dart:convert';
import 'package:flutter/material.dart';
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
      final user = UserModel.fromLoginJson(data['data']);

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
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token == null) {
        throw Exception('No token found');
      }

      final url = Uri.parse('$baseUrl/auth/logout');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success') {
          // Successful logout - clear local storage
          await _clearStorage();
          return;
        } else {
          throw Exception(responseData['message'] ?? 'Logout failed');
        }
      } else if (response.statusCode == 401) {
        // Token might be invalid, but we should still clear local storage
        await _clearStorage();
        throw Exception('Session expired or invalid');
      } else {
        throw Exception('Logout failed with status ${response.statusCode}');
      }
    } catch (e) {
      
      await _clearStorage();
      rethrow;
    }
  }

  Future<void> _clearStorage() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);

    // Clear any other relevant local storage
    // await Hive.box<VehicleModel>(HiveBoxes.vehiclesBox).clear();
    // await Hive.box<ArrivalTerminalModel>(HiveBoxes.arrivalTerminalsBox).clear();
  }

  Future<String?> getToken() => _storage.read(key: _tokenKey);

  Future<UserModel?> getUser() async {
    final token = await _storage.read(key: 'auth_token');

    final response = await http.get(
      Uri.parse('$baseUrl/auth/company-user/profile'),
      headers: {'Authorization': 'Bearer $token'},
    );

    print(
        'Raw response body: ${response.body}');

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      print('Decoded JSON: $json'); // Optional
      return UserModel.fromLoginJson(json['data']);
    } else {
      debugPrint('Failed to load user profile: ${response.body}');
      return null;
    }
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
