import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive/hive.dart';
import 'package:oro_ticket_app/app/modules/home/controllers/home_controller.dart';
import 'package:oro_ticket_app/app/modules/reset_password/view/reset_password_view.dart';
import 'package:oro_ticket_app/app/modules/sign_in/views/sign_in_view.dart';
import 'package:oro_ticket_app/app/modules/sign_in/services/auth_service.dart';
import 'package:oro_ticket_app/app/routes/app_pages.dart';
import 'package:get/get.dart';
import 'package:oro_ticket_app/core/theme/app_theme.dart';
import 'package:oro_ticket_app/core/utils/security_utils.dart';
import 'package:oro_ticket_app/data/locals/hive_boxes.dart';
import 'package:oro_ticket_app/app/modules/reset_password/controller/reset_password_controller.dart';
import 'package:oro_ticket_app/core/constants/colors.dart';
import 'package:oro_ticket_app/core/constants/typography.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveBoxes.init();
  await Hive.openBox('appState');
  await dotenv.load(fileName: ".env");

  // Initialize security utilities
  await _initializeSecurity();

  Get.put(AuthService());
  Get.put(HomeController());
  Get.put(ResetPasswordController());

  runApp(const MyApp());
}

Future<void> _initializeSecurity() async {
  try {
    // Check for emulator/simulator
    final isEmulator = await SecurityUtils.isRunningOnEmulator();
    if (isEmulator) {
      print('🚫 SECURITY ALERT: App cannot run on emulator/simulator');
      // Show error dialog and exit
      runApp(const EmulatorErrorApp());
      return;
    }

    // Check for rooted/jailbroken devices
    final isRooted = await SecurityUtils.isDeviceRooted();
    if (isRooted) {
      print('⚠️ SECURITY ALERT: Device appears to be rooted/jailbroken');
      // In production, you might want to show a warning or limit functionality
      // For now, we'll just log it and continue
    }

    // Initialize rate limiting cleanup
    SecurityUtils.cleanupRateLimits();

    print('✅ Security initialization completed');
  } catch (e) {
    print('❌ Security initialization failed: $e');
    // Continue even if security check fails to avoid breaking the app
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Hive.box('appState');
    final isFirstInstall = appState.get('isFirstInstall', defaultValue: true);

    return GetMaterialApp(
      theme: AppTheme.lightTheme,
      // Always start with Sign In page
      home: SignInView(),
      getPages: AppPages.routes,
      title: 'Oro Ticket App',
      debugShowCheckedModeBanner: false,
      routingCallback: (routing) {
        if (routing?.current != null && routing!.current != '/session-check') {
          Hive.box('appState').put('lastRoute', routing.current);
        }
      },
    );
  }
}

class EmulatorErrorApp extends StatelessWidget {
  const EmulatorErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.security,
                  size: 80,
                  color: AppColors.error,
                ),
                const SizedBox(height: 24),
                Text(
                  'Security Error',
                  style: AppTextStyles.heading1.copyWith(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'This application cannot run on emulators or simulators for security reasons.\n\nPlease use a physical device.',
                  style: AppTextStyles.body1,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
