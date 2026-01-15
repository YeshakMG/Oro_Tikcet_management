import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:oro_ticket_app/app/modules/sync/view/sync_view.dart';
import 'package:oro_ticket_app/core/constants/colors.dart';
import 'package:oro_ticket_app/core/utils/security_utils.dart';
import 'package:oro_ticket_app/data/locals/models/departure_terminal_model.dart';
import 'package:oro_ticket_app/data/locals/models/trip_model.dart';
import 'package:oro_ticket_app/data/locals/service/departure_terminal_storage_service.dart';
import 'package:oro_ticket_app/data/locals/service/user_storage_service.dart';
import 'package:oro_ticket_app/data/repositories/sync_repository.dart';
import '../../../../data/locals/hive_boxes.dart';
import '../../../../data/locals/models/service_charge_model.dart';
import '../../../../data/locals/models/user_model.dart';
import '../controllers/sign_in_controller.dart';

class AuthService {
  static final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';
  final SyncRepository syncRepo = Get.put(SyncRepository());

  // Use secure HTTP client for all network requests
  late final http.Client _secureClient;
  bool _secureClientInitialized = false;

  AuthService() {
    // Initialize cleanup timer for rate limits (runs every hour)
    Timer.periodic(const Duration(hours: 1), (_) async => await SecurityUtils.cleanupRateLimits());
  }

  // Initialize secure client
  Future<void> _initSecureClient() async {
    _secureClient = await SecurityUtils.createSecureHttpClient();
  }

  static const String baseUrl = 'https://admin.ota.gov.et/api';
  static const _loginRateLimitKey = 'login_rate_limit';

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    // Check if base URL is configured
    if (baseUrl.isEmpty) {
      return {
        'success': false,
        'message': 'Base URL not configured. Please check app configuration.',
        'error_type': 'config'
      };
    }

    // Initialize secure client if not already done
    if (!_secureClientInitialized) {
      await _initSecureClient();
      _secureClientInitialized = true;
    }

    // Check rate limiting - max 5 attempts per minute
    final isAllowed = await SecurityUtils.checkRateLimit(
      _loginRateLimitKey,
      maxRequests: 5,
      window: const Duration(minutes: 1)
    );

    if (!isAllowed) {
      return {
        'success': false,
        'message': 'Too many login attempts. Please wait 1 minute before trying again.',
        'rate_limited': true,
        'snackbar_title': 'Rate Limit Exceeded',
        'snackbar_message': 'For security reasons, login attempts are limited. Please wait 1 minute before trying again.'
      };
    }

    try {
      final url = Uri.parse('$baseUrl/auth/company-user/login');
      final response = await _secureClient
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

      print('Change Password Response: ${response.body}');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        final token = data['data']['token'];
        final user = UserModel.fromLoginJson(data['data']);

        // Store in secure storage with encryption
        print('🔐 Encrypting and storing token securely...');
        await SecurityUtils.secureStore(_tokenKey, token);
        await UserStorageService.saveUser(user);

        // Verify token was stored and can be decrypted
        final storedToken = await SecurityUtils.secureRetrieve(_tokenKey);
        if (storedToken == null) {
          throw Exception('Failed to store authentication token securely');
        }
        if (storedToken != token) {
          throw Exception('Token encryption/decryption verification failed');
        }
        print('✅ Token encrypted and stored successfully');

        // Sync critical data in background
        syncUserDataAfterLogin();

        return {'success': true, 'user': user, 'token': token};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Login failed',
          'errors': data['errors'] ?? [],
          'statusCode': response.statusCode
        };
      }
    } catch (e) {
      // Check if we have cached user data for offline login
      final lastUser = await UserStorageService.getUser();
      if (lastUser != null && email == lastUser.email) {
        final token = await SecurityUtils.secureRetrieve(_tokenKey);
        if (token != null) {
          return {
            'success': true,
            'user': lastUser,
            'token': token,
            'offline': true
          };
        }
      }
      return {
        'success': false,
        'message': 'Connection failed: ${e.toString()}',
        'error_type': 'network',
        'details': e.toString()
      };
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

  Future<bool> logout() async {
    try {
      print('🔄 Step 1: Starting logout process...');

      // 1️⃣ Check for any unsynced data
      print('🔍 Step 2: Checking for unsynced data...');
      final unsyncedTrips = _getUnsyncedTrips();
      final unsyncedServiceCharges = _getUnsyncedServiceCharges();

      print('🔍 Step 3: Found ${unsyncedTrips.length} unsynced trips and ${unsyncedServiceCharges.length} unsynced service charges');

      if (unsyncedTrips.isNotEmpty || unsyncedServiceCharges.isNotEmpty) {
        print('❌ Step 4: Unsynced data detected - aborting logout');
        print('   - Unsynced trips: ${unsyncedTrips.length}');
        print('   - Unsynced service charges: ${unsyncedServiceCharges.length}');
        print('❌ Logout aborted due to unsynced data');
        return false; // Don't logout if unsynced data exists
      }

      print('✅ Step 4: No unsynced data found - proceeding with logout');

      print('🧹 Step 5: Clearing local storage...');
      // 2️⃣ Proceed with logout - clear local storage and navigate
      await _clearStorage();
      print('✅ Step 6: Storage cleared successfully');

      print('🔀 Step 7: Navigating to sign-in page...');

      // Ensure sign-in fields are cleared by deleting any existing controller
      if (Get.isRegistered<SignInController>()) {
        Get.delete<SignInController>();
      }

      Get.offAllNamed('/sign-in');
      print('✅ Step 8: Navigation completed');

      // Optional: Try server logout in background (don't block on it)
      print('🌐 Step 9: Attempting server logout in background...');
      _performServerLogout();

      print('🎉 Step 10: Logout process completed successfully');
      return true;

    } catch (e) {
      print('❌ Logout error in step processing: $e');
      return false;
    }
  }

  Future<void> _performServerLogout() async {
    try {
      // Initialize secure client if needed
      if (!_secureClientInitialized) {
        await _initSecureClient();
        _secureClientInitialized = true;
      }

      // Note: We don't have a stored token anymore since we cleared storage
      // If server logout is needed, we'd need to call it before clearing storage
      // For now, just local logout is sufficient
      print('✅ Local logout completed');
    } catch (e) {
      print('⚠️ Server logout failed (local logout still successful): $e');
    }
  }


  /// Helper method to get unsynced trips
  List<TripModel> _getUnsyncedTrips() {
    final tripBox = Hive.box<TripModel>(HiveBoxes.tripBox);
    return tripBox.values.where((trip) => trip.isSynced != true).toList();
  }

  /// Helper method to get unsynced service charges
  List<ServiceChargeModel> _getUnsyncedServiceCharges() {
    final serviceChargeBox = Hive.box<ServiceChargeModel>('serviceChargeBox');
    return serviceChargeBox.values.toList();
  }

  Future<void> _clearStorage() async {
    print('   - Deleting authentication token...');
    await SecurityUtils.secureDelete(_tokenKey);
    print('   - Deleting user data...');
    await _storage.delete(key: _userKey); // User data doesn't need encryption
    UserStorageService.clearUser();
    print('   - Clearing trip data...');
    await Hive.box<TripModel>(HiveBoxes.tripBox).clear();
    print('   - Storage cleanup completed');
  }

  Future<String?> getToken() async {
    // Ensure secure client is initialized for any subsequent API calls
    if (!_secureClientInitialized) {
      await _initSecureClient();
      _secureClientInitialized = true;
    }
    final token = await SecurityUtils.secureRetrieve(_tokenKey);
    print('🔑 Retrieved encrypted token: ${token != null ? "YES (length: ${token.length})" : "NO"}');
    return token;
  }

  Future<UserModel?> getUser() async {
    try {
      // Initialize secure client if needed
      if (!_secureClientInitialized) {
        await _initSecureClient();
        _secureClientInitialized = true;
      }

      // Try to get fresh data if online
      if (await syncRepo.isOnline) {
        final token = await SecurityUtils.secureRetrieve(_tokenKey);
        if (token != null) {
          final response = await _secureClient.get(
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
    final token = await SecurityUtils.secureRetrieve(_tokenKey);
    if (token == null) return false;

    // Check if we have user data
    final user = await UserStorageService.getUser();
    return user != null;
  }

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    // Check if base URL is configured
    if (baseUrl.isEmpty) {
      return {
        'success': false,
        'message': 'Base URL not configured. Please check app configuration.',
        'error_type': 'config'
      };
    }

    // Initialize secure client if not already done
    if (!_secureClientInitialized) {
      await _initSecureClient();
      _secureClientInitialized = true;
    }

    try {
      final token = await getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No authentication token found. Please log in again.',
        };
      }

      final url = Uri.parse('$baseUrl/users/password/change-password');
      final response = await _secureClient
          .put(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'current_password': currentPassword,
              'new_password': newPassword,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        return {'success': true, 'message': 'Password changed successfully'};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to change password',
          'errors': data['errors'] ?? [],
          'statusCode': response.statusCode
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection failed: ${e.toString()}',
        'error_type': 'network',
        'details': e.toString()
      };
    }
  }

  Future<void> fetchAndStoreProfileData() async {
    final token = await getToken();
    if (token == null) return;

    final url = Uri.parse('$baseUrl/auth/company-user/profile');
    final response = await _secureClient.get(
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
