import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive/hive.dart';
import 'package:oro_ticket_app/app/modules/home/controllers/home_controller.dart';
import 'package:oro_ticket_app/app/modules/home/views/home_view.dart';
import 'package:oro_ticket_app/app/modules/reset_password/view/reset_password_view.dart';
import 'package:oro_ticket_app/app/modules/sign_in/views/sign_in_view.dart';
import 'package:oro_ticket_app/app/modules/sign_in/services/auth_service.dart';
import 'package:oro_ticket_app/app/modules/utils/device_security_checker.dart';
import 'package:oro_ticket_app/app/routes/app_pages.dart';
import 'package:get/get.dart';
import 'package:oro_ticket_app/core/theme/app_theme.dart';
import 'package:oro_ticket_app/data/locals/hive_boxes.dart';
import 'package:oro_ticket_app/app/modules/reset_password/controller/reset_password_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Check device security before starting the app
  final isSecure = await DeviceSecurityChecker.isDeviceSecure();
  if (!isSecure) {
    DeviceSecurityChecker.showSecurityErrorAndExit(
      DeviceSecurityChecker.blockedReason,
    );
    return;
  }
  
  await HiveBoxes.init();
  await Hive.openBox('appState');
  await dotenv.load(fileName: ".env");

  Get.put(AuthService());
  Get.put(HomeController());
  Get.put(ResetPasswordController());

  // Check if user is already logged in
  final authService = Get.find<AuthService>();
  final isLoggedIn = await authService.isLoggedIn();

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    final appState = Hive.box('appState');
    final isFirstInstall = appState.get('isFirstInstall', defaultValue: true);

    return GetMaterialApp(
      theme: AppTheme.lightTheme,
      // If user is already logged in, go to home, otherwise go to sign-in
      home: isLoggedIn ? HomeView() : SignInView(),
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
