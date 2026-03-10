import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

class ChangePasswordController extends GetxController {
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  var isLoading = false.obs;
  var errorMessage = ''.obs;
  var successMessage = ''.obs;

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
      // TODO: Replace this with your actual API call
      // For now, simulate API call
      await Future.delayed(const Duration(seconds: 2));

      // Get stored user data to verify current password
      final userBox = Hive.box('userBox');
      final storedPassword = userBox.get('password', defaultValue: '');

      // Simple password verification (in production, this should be done server-side)
      if (storedPassword != currentPasswordController.text) {
        errorMessage.value = "Current password is incorrect";
        isLoading.value = false;
        return;
      }

      // Update password in local storage
      await userBox.put('password', newPasswordController.text);

      // Success
      successMessage.value = "Password changed successfully!";
      
      // Clear form
      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();

      // Navigate back after short delay
      await Future.delayed(const Duration(seconds: 1));
      Get.back();
    } catch (e) {
      errorMessage.value = "Failed to change password. Please try again.";
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
