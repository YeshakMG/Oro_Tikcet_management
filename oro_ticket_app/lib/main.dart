import 'package:flutter/material.dart';
import 'package:oro_ticket_app/app/routes/app_pages.dart';
import 'package:get/get.dart';
import 'package:oro_ticket_app/core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      theme: AppTheme.lightTheme,
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
      title: 'Oro Ticket App',
      debugShowCheckedModeBanner: false,
    );
  }
}
