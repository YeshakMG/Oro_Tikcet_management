// lib/modules/auth/controllers/sign_in_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oro_ticket_app/core/constants/colors.dart';

import '../../home/controllers/home_controller.dart';
import '../../../../data/locals/models/user_model.dart';
import '../services/auth_service.dart';

class SignInController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final isPasswordVisible = false.obs;
  final isLoading = false.obs;
  final loginError = ''.obs;

  // Form key
  final formKey = GlobalKey<FormState>();

  @override
  void onInit() {
    super.onInit();
    // Clear text fields when sign-in view is initialized (including after logout)
    clearFields();
  }

  void clearFields() {
    emailController.clear();
    passwordController.clear();
    loginError.value = '';
    isPasswordVisible.value = false;
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  // Validate and submit login
  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    isLoading.value = true;

    try {
      final result = await _authService.login(email: email, password: password);

      if (result['success'] == true) {
        final homeController = Get.find<HomeController>();
        homeController.loadUser();
        await _authService.fetchAndStoreProfileData();

        // Show success message before navigation
        Get.snackbar(
          'Success',
          'Login successful',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: AppColors.backgroundAlt,
          duration: const Duration(seconds: 2),
        );

        // Navigate after snackbar finishes
        Future.delayed(const Duration(seconds: 2, milliseconds: 500), () {
          Get.offAllNamed('/home');
        });
      } else {
        _handleLoginError(result);
      }
    } catch (e) {
      print("Error:$e");
      Get.snackbar(
        'Login Error',
        'Network error occurred. Please check your connection and try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: AppColors.titleAlt,
        duration: const Duration(seconds: 4),
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _handleLoginError(Map<String, dynamic> result) {
    String title = 'Login Failed';
    String message = 'An error occurred during login';

    // 1. Check for rate limiting (handled before server request)
    if (result['rate_limited'] == true) {
      title = result['snackbar_title'] ?? 'Rate Limit Exceeded';
      message = result['snackbar_message'] ?? 'For security reasons, login attempts are limited. Please wait before trying again.';
    }
    // 2. Handle HTTP status code based errors
    else if (result['statusCode'] != null) {
      final statusCode = result['statusCode'] as int;
      switch (statusCode) {
        case 400:
          title = 'Bad Request';
          message = result['message'] ?? 'Invalid request data';
          break;
        case 401:
          title = 'Unauthorized';
          message = 'Invalid email or password';
          break;
        case 403:
          title = 'Forbidden';
          message = 'Access denied';
          break;
        case 404:
          title = 'Not Found';
          message = 'Login endpoint not found';
          break;
        case 422:
          title = 'Validation Error';
          message = result['message'] ?? 'Validation failed';
          break;
        case 429:
          title = 'Too Many Requests';
          message = 'Rate limit exceeded, please try again later';
          break;
        case 500:
          title = 'Server Error';
          message = 'Internal server error, please try again later';
          break;
        case 502:
          title = 'Bad Gateway';
          message = 'Server temporarily unavailable';
          break;
        case 503:
          title = 'Service Unavailable';
          message = 'Service is currently unavailable';
          break;
        default:
          title = 'Login Error';
          message = result['message'] ?? 'An unexpected error occurred';
      }
    }
    // 3. Handle field validation errors from server (fallback)
    else if (result['errors'] != null && result['errors'] is List) {
      final errors = result['errors'] as List;
      if (errors.isNotEmpty) {
        final firstError = errors.first;
        if (firstError is Map && firstError['msg'] != null) {
          title = 'Validation Error';
          message = firstError['msg'].toString();
        } else if (firstError is String) {
          title = 'Validation Error';
          message = firstError;
        }
      }
    }
    // 4. Handle specific error types
    else if (result['error_type'] == 'config') {
      title = 'Configuration Error';
      message = result['message'] ?? 'App configuration issue detected';
    }
    else if (result['error_type'] == 'network') {
      title = 'Connection Error';
      message = result['message'] ?? 'Network connection failed';
    }
    // 5. Handle specific server messages (fallback)
    else if (result['message'] != null) {
      message = result['message'].toString();
    }

    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.error,
      colorText: AppColors.titleAlt,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
