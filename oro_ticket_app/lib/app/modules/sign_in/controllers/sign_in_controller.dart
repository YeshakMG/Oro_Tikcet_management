// lib/modules/auth/controllers/sign_in_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oro_ticket_app/core/constants/colors.dart';

import '../../home/controllers/home_controller.dart';
import '../../../../data/locals/models/user_model.dart';
import '../services/auth_service.dart';

class SignInController extends GetxController {
  final AuthService _authService = AuthService();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final isPasswordVisible = false.obs;
  final isLoading = false.obs;
  final loginError = ''.obs;

  // Field-specific error messages
  final emailError = ''.obs;
  final passwordError = ''.obs;

  // Form key
  final formKey = GlobalKey<FormState>();

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  // Clear field errors
  void clearErrors() {
    emailError.value = '';
    passwordError.value = '';
    loginError.value = '';
  }

  // Clear input fields
  void clearFields() {
    emailController.clear();
    passwordController.clear();
    clearErrors();
  }

  // Validate email format (simple check)
  bool isValidEmail(String email) {
    return email.contains('@') && email.contains('.');
  }

  // Validate and submit login
  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    // Clear previous errors and snackbars
    clearErrors();
    Get.closeAllSnackbars();

    // Validate email field
    if (email.isEmpty) {
      emailError.value = 'Email is required';
      return;
    }

    if (!isValidEmail(email)) {
      emailError.value = 'Please enter a valid email address';
      return;
    }

    // Validate password field
    if (password.isEmpty) {
      passwordError.value = 'Password is required';
      return;
    }

    if (password.length < 6) {
      passwordError.value = 'Password must be at least 6 characters';
      return;
    }

    isLoading.value = true;

    try {
      final result = await _authService.login(email: email, password: password);

      // Print API response to console
      print('=== LOGIN API RESPONSE ===');
      print(result);
      print('=========================');

      if (result['success'] == true) {
        final UserModel user = result['user'];
        final homeController = Get.find<HomeController>();
        homeController.loadUser();
        await _authService.fetchAndStoreProfileData();

        Get.snackbar(
          'Success',
          'Login Successful.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: AppColors.backgroundAlt,
        );
        Get.offAllNamed('/home');
      } else {
        _handleLoginError(result);
      }
    } catch (e) {
      // Handle network errors
      String errorMessage = _getNetworkErrorMessage(e);
      loginError.value = errorMessage;
      Get.snackbar(
        'Connection Error',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Get user-friendly network error message
  String _getNetworkErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('socketexception') || 
        errorString.contains('connection refused') ||
        errorString.contains('connection timeout') ||
        errorString.contains('no internet')) {
      return 'No internet connection. Please check your network.';
    }
    
    if (errorString.contains('timeout') || errorString.contains('timeoutexception')) {
      return 'Request timed out. Please try again.';
    }
    
    if (errorString.contains('handshakexception') || errorString.contains('ssl')) {
      return 'Secure connection failed. Please try again.';
    }
    
    if (errorString.contains('formatexception') || errorString.contains('json')) {
      return 'Server error. Please contact support.';
    }
    
    return 'Unable to connect to server. Please try again later.';
  }

  void _handleLoginError(Map<String, dynamic> result) {
    // 1. Check for specific invalid credentials case
    if (result['message']?.toLowerCase().contains('invalid credentials') ??
        false) {
      passwordError.value = 'Invalid email or password';
      loginError.value = 'Login failed';
      return;
    }

    // 2. Handle field validation errors from server
    if (result['errors'] != null && result['errors'] is List) {
      for (var error in result['errors'] as List) {
        if (error is Map) {
          final param = error['param']?.toString().toLowerCase() ?? '';
          final msg = error['msg']?.toString() ?? 'Validation error';
          
          if (param.contains('email')) {
            emailError.value = msg;
          } else if (param.contains('password')) {
            passwordError.value = msg;
          } else {
            loginError.value = msg;
          }
        }
      }
      return;
    }

    // 3. Check for server errors
    if (result['message'] != null) {
      final message = result['message'].toString().toLowerCase();
      
      if (message.contains('email') || message.contains('user')) {
        emailError.value = result['message'];
      } else if (message.contains('password')) {
        passwordError.value = result['message'];
      } else {
        loginError.value = result['message'];
      }
      return;
    }

    // 4. Fallback to generic error message
    loginError.value = 'An error occurred. Please try again.';
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
