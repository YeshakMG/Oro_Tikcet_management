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
import 'package:oro_ticket_app/data/locals/models/service_charge_model.dart';
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

  final String baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://196.189.247.242:4501/api';

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/auth/company-user/login');
      
      // Print full request details
      print('=== LOGIN REQUEST ===');
      print('URL: $url');
      print('Email: $email');
      print('===================');
      
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      // Print full response details
      print('=== LOGIN RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: $data');
      print('======================');

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
      // 1️⃣ Check for unsynced trips
      final unsyncedTrips = _getUnsyncedTrips();

      // 2️⃣ Check for unsynced service charges (any service charges in the box need syncing)
      final serviceChargeBox = Hive.box<ServiceChargeModel>(HiveBoxes.serviceChargeBox);
      final hasUnsyncedServiceCharges = serviceChargeBox.isNotEmpty;

      if (unsyncedTrips.isNotEmpty || hasUnsyncedServiceCharges) {
        final tripCount = unsyncedTrips.length;
        final serviceChargeCount = hasUnsyncedServiceCharges ? 1 : 0; // Simplified count

        _redirectToHomeForSync(tripCount + serviceChargeCount);
        return;
      }

      // 3️⃣ Proceed with normal logout if everything is synced
      await _clearStorage();
      Get.offAllNamed('/sign-in');
    } catch (e) {
      print('Logout error: $e');
      Get.snackbar(
        'Logout Error!',
        'Try Again Later',
        snackPosition: SnackPosition.BOTTOM,
      );
      rethrow;
    }
  }

  void _redirectToHomeForSync(int unsyncedCount) {
    Get.off(SyncView());
    Get.snackbar(
      'Unsynced Data Found',
      'Please sync your data before logging out',
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
    // Clear secure storage
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);

    // Clear user storage service
    UserStorageService.clearUser();

    // Clear all Hive boxes
    await Hive.box<TripModel>(HiveBoxes.tripBox).clear();
    await Hive.box(HiveBoxes.vehiclesBox).clear();
    await Hive.box(HiveBoxes.departureTerminalsBox).clear();
    await Hive.box(HiveBoxes.arrivalTerminalsBox).clear();
    await Hive.box(HiveBoxes.commissionRulesBox).clear();
    await Hive.box(HiveBoxes.serviceChargeBox).clear();
    await Hive.box(HiveBoxes.userBox).clear();
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
