// lib/modules/auth/controllers/sign_in_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SignInController extends GetxController {

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final isPasswordVisible = false.obs;
  final isLoading = false.obs;

  // Form key
  final formKey = GlobalKey<FormState>();

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  // Validate and submit login
  void login() {
    // if (!formKey.currentState!.validate()) return;

    isLoading.value = true;

    //API call 
    Future.delayed(const Duration(seconds: 1), () {
      isLoading.value = false;

      Get.snackbar('Success', 'You have logged in successfully');
 
      Get.offAllNamed('/home');
    });
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
