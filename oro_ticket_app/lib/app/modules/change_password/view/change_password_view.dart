import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oro_ticket_app/app/modules/change_password/controller/change_password_controller.dart';
import 'package:oro_ticket_app/core/constants/colors.dart';
import 'package:oro_ticket_app/core/constants/typography.dart';

class ChangePasswordView extends GetView<ChangePasswordController> {
  const ChangePasswordView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final paddingHorizontal = size.width * 0.04;
    final paddingVertical = size.height * 0.02;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Change Password"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(paddingHorizontal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: paddingVertical * 2),
              // Lock icon
              const Icon(
                Icons.lock_outline,
                size: 64,
                color: AppColors.primary,
              ),
              SizedBox(height: paddingVertical * 2),
              // Title
              Text(
                "Update Your Password",
                style: AppTextStyles.heading2.copyWith(
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: paddingVertical),
              // Subtitle
              Text(
                "Enter your current password and choose a new one",
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.secondary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: paddingVertical * 3),
              // Current Password Field
              TextField(
                controller: controller.currentPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Current Password",
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              SizedBox(height: paddingVertical * 2),
              // New Password Field
              TextField(
                controller: controller.newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "New Password",
                  prefixIcon: const Icon(Icons.lock_open),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  helperText: "Minimum 6 characters",
                ),
              ),
              SizedBox(height: paddingVertical * 2),
              // Confirm Password Field
              TextField(
                controller: controller.confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Confirm New Password",
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              SizedBox(height: paddingVertical * 3),
              // Error Message
              Obx(() {
                if (controller.errorMessage.value.isNotEmpty) {
                  return Container(
                    padding: EdgeInsets.all(paddingHorizontal),
                    margin: EdgeInsets.only(bottom: paddingVertical * 2),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            controller.errorMessage.value,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
              // Success Message
              Obx(() {
                if (controller.successMessage.value.isNotEmpty) {
                  return Container(
                    padding: EdgeInsets.all(paddingHorizontal),
                    margin: EdgeInsets.only(bottom: paddingVertical * 2),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            controller.successMessage.value,
                            style: const TextStyle(color: Colors.green),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
              // Change Password Button
              Obx(() {
                if (controller.isLoading.value) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  );
                }
                return ElevatedButton(
                  onPressed: controller.changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: paddingVertical * 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    "Change Password",
                    style: AppTextStyles.button,
                  ),
                );
              }),
              SizedBox(height: paddingVertical * 2),
              // Cancel Button
              TextButton(
                onPressed: () => Get.back(),
                child: const Text(
                  "Cancel",
                  style: TextStyle(
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
