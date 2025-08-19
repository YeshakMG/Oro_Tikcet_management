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

  // Form key
  final formKey = GlobalKey<FormState>();

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  // Validate and submit login
  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    // Validate fields
    if (email.isEmpty || password.isEmpty) {
      Get.snackbar(
        'Missing Fields',
        'Please enter both email and password.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: AppColors.titleAlt,
      );
      return;
    }

    isLoading.value = true;

    try {
      final result = await _authService.login(email: email, password: password);

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
      print("Error:$e");
      Get.snackbar(
        'Login Error',
        'An unexpected error occurred. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: AppColors.titleAlt,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _handleLoginError(Map<String, dynamic> result) {
    // 1. Check for specific invalid credentials case
    if (result['message']?.toLowerCase().contains('invalid credentials') ??
        false) {
      Get.snackbar(
        'Login Failed',
        'Invalid email or password',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: AppColors.titleAlt,
      );
      return;
    }

    // 2. Handle field validation errors
    if (result['errors'] != null && result['errors'] is List) {
      for (var error in result['errors'] as List) {
        if (error is Map && error['msg'] != null) {
          Get.snackbar(
            'Validation Error',
            error['msg'].toString(),
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.error,
            colorText: AppColors.titleAlt,
          );
        }
      }
      return;
    }

    // 3. Fallback to generic error message
    Get.snackbar(
      'Login Failed',
      result['message']?.toString() ?? 'Unknown error occurred',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.error,
      colorText: AppColors.titleAlt,
    );
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
