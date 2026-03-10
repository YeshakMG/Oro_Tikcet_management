import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oro_ticket_app/app/modules/reset_password/controller/reset_password_controller.dart';

class ResetPasswordView extends GetView<ResetPasswordController> {
  const ResetPasswordView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final paddingHorizontal = size.width * 0.04; // 4% of screen width
    final paddingVertical = size.height * 0.02; // 2% of screen height

    return Scaffold(
      appBar: AppBar(title: const Text("Reset Password")),
      body: Padding(
        padding: EdgeInsets.all(paddingHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: controller.emailController,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: paddingVertical * 2),
            Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              return ElevatedButton(
                onPressed: controller.resetPassword,
                child: const Text("Reset Password"),
              );
            }),
            SizedBox(height: paddingVertical * 2),
            Obx(() => Text(
                  controller.resetError.value,
                  style: const TextStyle(color: Colors.red),
                )),
            Obx(() => Text(
                  controller.resetSuccess.value,
                  style: const TextStyle(color: Colors.green),
                )),
          ],
        ),
      ),
    );
  }
}
