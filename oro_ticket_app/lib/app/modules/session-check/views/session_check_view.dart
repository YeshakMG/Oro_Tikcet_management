import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:oro_ticket_app/app/modules/sign_in/services/auth_service.dart';

class SessionCheckView extends StatefulWidget {
  const SessionCheckView({super.key});

  @override
  State<SessionCheckView> createState() => _SessionCheckViewState();
}

class _SessionCheckViewState extends State<SessionCheckView> {
  final AuthService _authService = Get.find<AuthService>();

  @override
  void initState() {
    super.initState();
    debugPrint('🔍 SessionCheckView: initState called');
    _checkSession();
  }

  Future<void> _checkSession() async {
    debugPrint('🔍 SessionCheckView: _checkSession started');
    await Future.delayed(const Duration(milliseconds: 300));
    debugPrint('🔍 SessionCheckView: delay done, calling isLoggedIn...');

    bool loggedIn = false;
    try {
      loggedIn = await _authService.isLoggedIn().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint(
              '❌ SessionCheckView: isLoggedIn() TIMED OUT — AuthService is hanging');
          return false;
        },
      );
    } catch (e) {
      debugPrint('❌ SessionCheckView: isLoggedIn() threw: $e');
    }

    debugPrint('🔍 SessionCheckView: loggedIn = $loggedIn, navigating...');

    if (loggedIn) {
      String? lastRoute = Hive.box('appState').get('lastRoute');
      if (lastRoute != null && lastRoute != '/session-check') {
        Get.offNamed(lastRoute);
      } else {
        Get.offNamed('/home');
      }
    } else {
      Get.offAllNamed('/splash-screen');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
