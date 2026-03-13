import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ChangePasswordController extends GetxController {
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  var isLoading = false.obs;
  var errorMessage = ''.obs;
  var successMessage = ''.obs;

  // Password visibility toggles
  var isCurrentPasswordVisible = true.obs;
  var isNewPasswordVisible = true.obs;
  var isConfirmPasswordVisible = true.obs;

  final _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  static const _tokenKey = 'auth_token';

  final String baseUrl = 'https://company.ota.gov.et/api';

  /// Validate and change password
  Future<void> changePassword() async {
    // Validate inputs
    if (currentPasswordController.text.isEmpty) {
      errorMessage.value = "Please enter your current password";
      return;
    }

    if (newPasswordController.text.isEmpty) {
      errorMessage.value = "Please enter a new password";
      return;
    }

    if (newPasswordController.text.length < 6) {
      errorMessage.value = "New password must be at least 6 characters";
      return;
    }

    if (confirmPasswordController.text.isEmpty) {
      errorMessage.value = "Please confirm your new password";
      return;
    }

    if (newPasswordController.text != confirmPasswordController.text) {
      errorMessage.value = "New passwords do not match";
      return;
    }

    // Reset messages
    errorMessage.value = "";
    successMessage.value = "";
    isLoading.value = true;

    try {
      // Get auth token
      final token = await _storage.read(key: _tokenKey);
      if (token == null) {
        errorMessage.value = "Session expired. Please login again.";
        isLoading.value = false;
        return;
      }

      // Make API call to change password
      final url = Uri.parse('$baseUrl/users/password/change-password');
      
      print('=== CHANGE PASSWORD REQUEST ===');
      print('URL: $url');
      print('Current Password: ${currentPasswordController.text}');
      print('================================');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'current_password': currentPasswordController.text,
              'new_password': newPasswordController.text,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      print('=== CHANGE PASSWORD RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: $data');
      print('=================================');

      if (response.statusCode == 200 && data['status'] == 'success') {
        // Success
        successMessage.value = data['message'] ?? "Password changed successfully!";
        
        // Clear form
        currentPasswordController.clear();
        newPasswordController.clear();
        confirmPasswordController.clear();

        // Navigate back after short delay
        await Future.delayed(const Duration(seconds: 2));
        Get.back();
      } else {
        // Handle error response from server
        final errorMsg = data['message'] ?? data['error'] ?? 'Failed to change password';
        errorMessage.value = errorMsg;
      }
    } catch (e) {
      // Handle connection errors
      String errorMessageText = 'Failed to change password. Please try again.';
      if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
        errorMessageText = 'Unable to connect to server. Please check your internet connection.';
      } else if (e.toString().contains('timeout')) {
        errorMessageText = 'Connection timed out. Please try again.';
      }
      errorMessage.value = errorMessageText;
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
