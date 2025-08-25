import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:oro_ticket_app/app/modules/sync/view/sync_view.dart';
import 'package:oro_ticket_app/core/constants/colors.dart';
import 'package:oro_ticket_app/data/locals/models/departure_terminal_model.dart';
import 'package:oro_ticket_app/data/locals/models/trip_model.dart';
import 'package:oro_ticket_app/data/locals/service/departure_terminal_storage_service.dart';
import 'package:oro_ticket_app/data/locals/service/user_storage_service.dart';
import 'package:oro_ticket_app/data/repositories/sync_repository.dart';
import '../../../../data/locals/hive_boxes.dart';
import '../../../../data/locals/models/user_model.dart';

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
    try {
      final url = Uri.parse('$baseUrl/auth/company-user/login');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        final token = data['data']['token'];
        final user = UserModel.fromLoginJson(data['data']);

        // Store in secure storage and Hive
        await _storage.write(key: _tokenKey, value: token);
        await UserStorageService.saveUser(user);

        // Sync critical data in background
        syncUserDataAfterLogin();

        return {'success': true, 'user': user, 'token': token};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Login failed',
          'errors': data['errors'] ?? []
        };
      }
    } catch (e) {
      // Check if we have cached user data for offline login
      final lastUser = await UserStorageService.getUser();
      if (lastUser != null && email == lastUser.email) {
        final token = await _storage.read(key: _tokenKey);
        if (token != null) {
          return {
            'success': true,
            'user': lastUser,
            'token': token,
            'offline': true
          };
        }
      }
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<void> syncUserDataAfterLogin() async {
    try {
      await Future.wait([
        syncRepo.syncCommissionRules(),
        syncRepo.syncAllCompanyUserVehicles(),
        fetchAndStoreProfileData(),
      ]);
      print('✅ Critical data synced after login');
    } catch (e) {
      print('⚠️ Partial sync after login: $e');
    }
  }

  Future<void> logout() async {
    try {
      // 1️⃣ Check for unsynced trips (unless forced logout)
      final unsyncedTrips = _getUnsyncedTrips();
      if (unsyncedTrips.isNotEmpty) {
        if (unsyncedTrips.isNotEmpty) {
          _redirectToHomeForSync(unsyncedTrips.length);
          return;
        }
      }

      // // 2️⃣ Proceed with normal logout
      // final token = await _storage.read(key: _tokenKey);
      // if (token == null) throw Exception('No token found');

      // final response = await http.post(
      //   Uri.parse('$baseUrl/auth/logout'),
      //   headers: {
      //     'Authorization': 'Bearer $token',
      //     'Content-Type': 'application/json',
      //   },
      // );

      // if (response.statusCode == 200) {
        await _clearStorage();
        Get.offAllNamed('/login');
      // } else {
      //   print('❌ Logout failed: ${response.statusCode} ${response.body}');
      //   throw Exception('Logout failed with status ${response.statusCode}');
      // }
    } catch (e) {
      Get.snackbar(
        'Logout Error!',
        'Try Again Later',
        // e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
      print("error: $e");
      rethrow;
    }
  }

  void _redirectToHomeForSync(int unsyncedCount) {
    Get.off(SyncView());
    Get.snackbar(
      'Unsynced Trips Found',
      'Please sync your $unsyncedCount trip(s) before logging out',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.error,
      colorText: AppColors.background,
      duration: Duration(seconds: 5),
    );
  }

  /// Helper method to get unsynced trips
  List<TripModel> _getUnsyncedTrips() {
    final tripBox = Hive.box<TripModel>(HiveBoxes.tripBox);
    return tripBox.values.where((trip) => trip.isSynced != true).toList();
  }

  Future<void> _clearStorage() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
    UserStorageService.clearUser();
    await Hive.box<TripModel>(HiveBoxes.tripBox).clear();
  }

  Future<String?> getToken() => _storage.read(key: _tokenKey);

  Future<UserModel?> getUser() async {
    try {
      // Try to get fresh data if online
      if (await syncRepo.isOnline) {
        final token = await _storage.read(key: _tokenKey);
        if (token != null) {
          final response = await http.get(
            Uri.parse('$baseUrl/auth/company-user/profile'),
            headers: {'Authorization': 'Bearer $token'},
          ).timeout(const Duration(seconds: 5));

          if (response.statusCode == 200) {
            final user =
                UserModel.fromLoginJson(jsonDecode(response.body)['data']);
            await UserStorageService.saveUser(user);
            return user;
          }
        }
      }

      // Fall back to local storage
      return await UserStorageService.getUser();
    } catch (e) {
      return await UserStorageService.getUser();
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) return false;

    // Check if we have user data
    final user = await UserStorageService.getUser();
    return user != null;
  }

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
