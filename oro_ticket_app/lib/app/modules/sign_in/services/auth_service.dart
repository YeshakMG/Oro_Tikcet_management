import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:oro_ticket_app/data/locals/hive_boxes.dart';
import '../../../../data/locals/models/user_model.dart';
import '../controllers/sign_in_controller.dart';

class AuthService {
  static final _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';
  static const _tokenExpiryKey = 'auth_token_expiry';
  static const _userEmailKey = 'user_email';
  static const _userPasswordKey = 'user_password';
  static const _refreshTokenKey = 'refresh_token';
  final SyncRepository syncRepo = Get.put(SyncRepository());

  // Token expires after 20 days (as per API)
  static const Duration tokenExpiryDuration = Duration(days: 20);

  final String baseUrl = dotenv.env['API_BASE_URL'] ?? 'https://admin.ota.gov.et/api';

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
        final refreshToken = data['data']['refreshToken'];
        final user = UserModel.fromLoginJson(data['data']);

        // Store in secure storage and Hive
        await _storage.write(key: _tokenKey, value: token);
        // Store refresh token if provided
        if (refreshToken != null) {
          await _storage.write(key: _refreshTokenKey, value: refreshToken);
        }
        // Store token expiry time
        final expiryTime = DateTime.now().add(tokenExpiryDuration);
        await _storage.write(key: _tokenExpiryKey, value: expiryTime.toIso8601String());
        // Store user credentials for auto-refresh
        await _storage.write(key: _userEmailKey, value: email);
        await _storage.write(key: _userPasswordKey, value: password);
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
      // But only if token is not expired
      final lastUser = await UserStorageService.getUser();
      if (lastUser != null && email == lastUser.email) {
        final token = await _storage.read(key: _tokenKey);
        // Check if token exists AND is not expired
        if (token != null && !(await isTokenExpired())) {
          return {
            'success': true,
            'user': lastUser,
            'token': token,
            'offline': true
          };
        } else {
          // Token is expired - user must login again
          return {
            'success': false,
            'message': 'Session expired. Please login again.',
            'errors': []
          };
        }
      }
      // Show user-friendly error message
      String errorMessage = 'Connection failed. Please try again.';
      if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
        errorMessage = 'Unable to connect to server. Please check your internet connection.';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'Connection timed out. Please try again.';
      }
      return {'success': false, 'message': errorMessage};
    }
  }

  Future<void> syncUserDataAfterLogin() async {
    try {
      // Check if we've synced recently (within last hour) to avoid unnecessary syncs
      final lastSync = await syncRepo.getLastVehicleSyncTime();
      final now = DateTime.now();
      
      if (lastSync != null) {
        final difference = now.difference(lastSync);
        if (difference.inMinutes < 60) {
          print('✅ Skipping vehicle sync - last synced ${difference.inMinutes} minutes ago');
          // Still sync other data, but skip vehicles
          await Future.wait([
            syncRepo.syncCommissionRules(),
            fetchAndStoreProfileData(),
          ]);
          return;
        }
      }
      
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
      // Clear the sign-in input fields
      if (Get.isRegistered<SignInController>()) {
        Get.find<SignInController>().clearFields();
      }
      
      // Clear storage and navigate to sign-in
      await _clearStorage();
      Get.offAllNamed('/sign-in');
    } catch (e) {
      print('Logout error: $e');
      // Even if there's an error, try to navigate to sign-in
      Get.offAllNamed('/sign-in');
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
  Future<List<TripModel>> _getUnsyncedTrips() async {
    final tripBox = await HiveBoxes.getBox<TripModel>(HiveBoxes.tripBox);
    return tripBox.values.where((trip) => trip.isSynced != true).toList();
  }

  Future<void> _clearStorage() async {
    // Clear secure storage
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
    await _storage.delete(key: _tokenExpiryKey);
    await _storage.delete(key: _userEmailKey);
    await _storage.delete(key: _userPasswordKey);
    await _storage.delete(key: _refreshTokenKey);

    // Clear user storage service
    UserStorageService.clearUser();

    // Clear all Hive boxes using HiveBoxes
    await HiveBoxes.clearAllData();
  }

  Future<String?> getToken() => _storage.read(key: _tokenKey);

  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  /// Check if the stored token is expired
  Future<bool> isTokenExpired() async {
    try {
      final expiryString = await _storage.read(key: _tokenExpiryKey);
      if (expiryString == null) {
        // If no expiry stored, assume expired for safety
        return true;
      }
      final expiryTime = DateTime.parse(expiryString);
      return DateTime.now().isAfter(expiryTime);
    } catch (e) {
      // If error checking expiry, assume expired for safety
      print('Error checking token expiry: $e');
      return true;
    }
  }

  /// Check if token is valid (exists and not expired)
  Future<bool> isTokenValid() async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      return false;
    }
    return !(await isTokenExpired());
  }

  /// Refresh the access token using the stored refresh token
  /// Returns true if refresh was successful, false otherwise
  Future<bool> refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: _refreshTokenKey);
      
      if (refreshToken == null) {
        print('⚠️ No stored refresh token for token refresh');
        return false;
      }

      final currentToken = await getToken();
      if (currentToken == null) {
        return false;
      }

      print('🔄 Attempting to refresh token using refresh token...');
      
      final url = Uri.parse('$baseUrl/auth/refresh-token');
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $currentToken',
            },
            body: jsonEncode({'refreshToken': refreshToken}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final newToken = data['data']['token'];
          final newRefreshToken = data['data']['refreshToken'];
          
          // Store new token and refresh token, update expiry
          await _storage.write(key: _tokenKey, value: newToken);
          if (newRefreshToken != null) {
            await _storage.write(key: _refreshTokenKey, value: newRefreshToken);
          }
          final expiryTime = DateTime.now().add(tokenExpiryDuration);
          await _storage.write(key: _tokenExpiryKey, value: expiryTime.toIso8601String());
          
          print('✅ Token refreshed successfully using refresh token');
          return true;
        }
      }
      
      print('⚠️ Token refresh failed: ${response.statusCode} - ${response.body}');
      return false;
    } catch (e) {
      print('⚠️ Token refresh error: $e');
      return false;
    }
  }

  /// Try to refresh token, if fails then redirect to login
  Future<bool> tryRefreshToken() async {
    final refreshed = await refreshToken();
    if (!refreshed) {
      print('⚠️ Token refresh failed - forcing re-login');
      await handleTokenExpiration();
    }
    return refreshed;
  }

  /// Handle token expiration - clear auth data and redirect to login
  /// Preserves trip and service charge data so user can re-login and sync
  Future<void> handleTokenExpiration() async {
    print('⚠️ Token expired - forcing re-login (preserving trips and service charges)');
    
    // Clear only auth-related data, preserve trips and service charges
    await _clearAuthStorage();
    
    Get.offAllNamed('/sign-in');
    Get.snackbar(
      'Session Expired',
      'Your session has expired. Please login again to sync your data.',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
    );
  }

  /// Clear only auth-related storage (for token expiration)
  /// Preserves trip and service charge data
  Future<void> _clearAuthStorage() async {
    try {
      // Clear secure storage tokens
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _userKey);
      await _storage.delete(key: _tokenExpiryKey);
      // Clear refresh token
      await _storage.delete(key: _refreshTokenKey);
      // Clear saved credentials (user needs to login again)
      await _storage.delete(key: _userEmailKey);
      await _storage.delete(key: _userPasswordKey);
      
      // Clear user storage
      UserStorageService.clearUser();
      
      // Clear auth-related Hive boxes but preserve trips and service charges
      await HiveBoxes.clearAuthData();
      
      print('✅ Auth storage cleared (trips and service charges preserved)');
    } catch (e) {
      print('Error clearing auth storage: $e');
    }
  }

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

    // Check if token is expired
    if (await isTokenExpired()) {
      print('⚠️ Token expired - user not logged in');
      return false;
    }

    // Check if we have user data
    final user = await UserStorageService.getUser();
    return user != null;
  }

  Future<void> fetchAndStoreProfileData() async {
    // Check if token is valid before making API call
    if (await isTokenExpired()) {
      print('⚠️ Token expired - cannot fetch profile data');
      return;
    }
    
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
