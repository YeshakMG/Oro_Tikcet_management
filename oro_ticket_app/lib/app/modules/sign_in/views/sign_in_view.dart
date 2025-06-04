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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingMedium,
            vertical: AppDimensions.paddingMedium,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: AppDimensions.verticalSpacingLarge),

              // Logo
              Center(
                child: Image.asset(
                  'assets/logo/OTA_logo.png',
                  height: 150,
                ),
              ),

              SizedBox(height: AppDimensions.verticalSpacingLarge),

              // Title
              Text(
                'Sign in to your\nAccount',
                style: AppTextStyles.heading1,
              ),

              SizedBox(height: AppDimensions.verticalSpacingMedium),

              // Subtitle
              Text(
                'Enter your email and password to log in',
                style: AppTextStyles.subtitle3,
              ),

              SizedBox(height: AppDimensions.verticalSpacingMedium),

              // Email Field
              TextField(
                controller: controller.emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12))),
                  hoverColor: AppColors.primary,
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primaryHover),
                      borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
              ),

              SizedBox(height: AppDimensions.verticalSpacingMedium),

              // Password Field
              Obx(() => TextField(
                    controller: controller.passwordController,
                    obscureText: controller.isPasswordVisible.value,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12))),
                      hoverColor: AppColors.primary,
                      focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.primaryHover),
                          borderRadius: BorderRadius.all(Radius.circular(12))),
                      suffixIcon: IconButton(
                        icon: Icon(controller.isPasswordVisible.value
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: controller.togglePasswordVisibility,
                      ),
                    ),
                  )),

              SizedBox(height: AppDimensions.verticalSpacingMedium),

              // Login Button
              SizedBox(
                height: AppDimensions.buttonHeight,
                child: ElevatedButton(
                  onPressed: controller.login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.borderRadius),
                    ),
                  ),
                  child: Text(
                    'Log In',
                    style: AppTextStyles.button,
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
