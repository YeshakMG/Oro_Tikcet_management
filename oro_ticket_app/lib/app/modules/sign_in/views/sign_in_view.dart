import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oro_ticket_app/app/modules/sign_in/controllers/sign_in_controller.dart';
import 'package:oro_ticket_app/core/constants/colors.dart';
import 'package:oro_ticket_app/core/constants/dimensions.dart';
import 'package:oro_ticket_app/core/constants/typography.dart';

class SignInView extends StatelessWidget {
  final SignInController controller = Get.put(SignInController());

  SignInView({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final paddingHorizontal = size.width * 0.04; // 4% of screen width
    final paddingVertical = size.height * 0.02; // 2% of screen height

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: paddingHorizontal,
            vertical: paddingVertical,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: paddingVertical * 2.5),

              // Logo
              Center(
                child: Image.asset(
                  'assets/logo/OTA_logo.png',
                  height: size.height * 0.15,
                ),
              ),

              SizedBox(height: paddingVertical * 2.5),

              // Title
              Text(
                'Sign in to your \nAccount',
                style: AppTextStyles.heading1,
              ),

              SizedBox(height: paddingVertical * 1.5),

              Text(
                'Enter your email and password to log in',
                style: AppTextStyles.caption2,
              ),

              SizedBox(height: paddingVertical * 2.5),

              // General Error Message
              Obx(() {
                if (controller.loginError.value.isNotEmpty) {
                  return Container(
                    padding: EdgeInsets.all(paddingHorizontal),
                    margin: EdgeInsets.only(bottom: paddingVertical * 1.5),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            controller.loginError.value,
                            style: const TextStyle(color: Colors.red, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),

              // Email Field
              Obx(() => TextField(
                    controller: controller.emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      errorText: controller.emailError.value.isEmpty 
                          ? null 
                          : controller.emailError.value,
                      errorStyle: const TextStyle(color: Colors.red),
                      border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12))),
                      hoverColor: AppColors.primary,
                      focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.primaryHover),
                          borderRadius: const BorderRadius.all(Radius.circular(12))),
                    ),
                  )),

              SizedBox(height: paddingVertical * 1.5),

              // Password Field
              Obx(() => TextField(
                    controller: controller.passwordController,
                    obscureText: !controller.isPasswordVisible.value,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      errorText: controller.passwordError.value.isEmpty 
                          ? null 
                          : controller.passwordError.value,
                      errorStyle: const TextStyle(color: Colors.red),
                      border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12))),
                      hoverColor: AppColors.primary,
                      focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.primaryHover),
                          borderRadius: const BorderRadius.all(Radius.circular(12))),
                      suffixIcon: IconButton(
                        icon: Icon(controller.isPasswordVisible.value
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: controller.togglePasswordVisibility,
                      ),
                    ),
                  )),

              SizedBox(height: paddingVertical * 2.5),

              // Login Button
              Obx(() => SizedBox(
                    height: size.height * 0.06,
                    child: ElevatedButton(
                      onPressed:
                          controller.isLoading.value ? null : controller.login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18.0),
                        ),
                        disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                      ),
                      child: controller.isLoading.value
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Log In',
                              style: AppTextStyles.button,
                            ),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
