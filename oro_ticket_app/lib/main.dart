import 'dart:io';
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
import 'package:oro_ticket_app/core/utils/security_utils.dart';
import 'package:oro_ticket_app/data/locals/hive_boxes.dart';
import 'package:oro_ticket_app/app/modules/reset_password/controller/reset_password_controller.dart';
import 'package:oro_ticket_app/core/constants/colors.dart';
import 'package:oro_ticket_app/core/constants/typography.dart';
import 'package:oro_ticket_app/data/locals/service/connectivity_service.dart';
import 'package:oro_ticket_app/data/repositories/enhanced_sync_repository.dart';
import 'package:oro_ticket_app/data/locals/offline_tracking_service.dart';
import 'package:oro_ticket_app/data/locals/local_backup_service.dart';
import 'package:oro_ticket_app/data/repositories/sync_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('========================================');
  debugPrint('🚀 APP STARTING - Oro Ticket App');
  debugPrint('========================================');

  // Check device security before starting the app
  final isSecure = await DeviceSecurityChecker.isDeviceSecure();
  if (!isSecure) {
    DeviceSecurityChecker.showSecurityErrorAndExit(
      DeviceSecurityChecker.blockedReason,
    );
    return;
  }

  debugPrint('✅ Device security check passed');

  await HiveBoxes.init();
  debugPrint('✅ Hive boxes initialized');

  await Hive.openBox('appState');
  await dotenv.load(fileName: ".env");
  await LocalBackupService.requestStoragePermission();
  debugPrint('');
  debugPrint('========================================');
  debugPrint('🔄 CHECKING FOR BACKUP...');
  debugPrint('========================================');

  // Try to restore auth data from backup BEFORE checking isLoggedIn
  // This ensures the user doesn't need to login again after clearing data
  final authRestored = await _tryRestoreAuthFromBackup();
  debugPrint('🔐 Auth restoration result: $authRestored');

  // Check and update connectivity status on app start
  await OfflineTrackingService.checkConnectivity();
  // Start listening for connectivity changes
  OfflineTrackingService.startConnectivityListener();

  // Create initial backup on app start
  _createBackupInBackground();
  // Initialize security utilities
  // await _initializeSecurity();

  Get.put(AuthService());
  Get.put(SyncRepository()); // Register SyncRepository for server sync fallback
  Get.put(HomeController());
  Get.put(ResetPasswordController());
  Get.put(ConnectivityService());

  // Initialize enhanced sync repository
  final enhancedSyncRepo = EnhancedSyncRepository();

  // Start periodic sync
  enhancedSyncRepo.startPeriodicSync(
    interval: Duration(minutes: 5), // Check every 5 minutes
  );

  // Check if user is already logged in (token should be restored if backup existed)
  final authService = Get.find<AuthService>();

  // Check token specifically
  final token = await authService.getToken();
  debugPrint(
      '🔐 Token check: ${token != null ? "Token exists" : "Token is null"}');

  // Check both token and user for isLoggedIn
  final user = await authService.getUser();
  final isLoggedIn = token != null && user != null;

  debugPrint(
      '🔐 Is logged in after auth restore: $isLoggedIn (token: ${token != null}, user: ${user != null})');
  debugPrint('');

  // If auth was restored (token exists), restore other data in background
  if (token != null) {
    debugPrint('========================================');
    debugPrint('🔄 STARTING BACKGROUND DATA RESTORE');
    debugPrint('========================================');
    _restoreOtherDataInBackground();
  }

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

Future<bool> _tryRestoreAuthFromBackup() async {
  try {
    debugPrint('🔍 Checking hasAuthData...');

    final hasAuth = await LocalBackupService.hasAuthData()
        .timeout(const Duration(seconds: 4), onTimeout: () {
      debugPrint('❌ HUNG INSIDE: LocalBackupService.hasAuthData()');
      return false; // ← this is where it's probably dying
    });

    debugPrint('🔍 hasAuth: $hasAuth');
    if (!hasAuth) return false;

    debugPrint('🔐 Restoring auth data...');
    final result = await LocalBackupService.restoreAuthData()
        .timeout(const Duration(seconds: 4), onTimeout: () {
      debugPrint('❌ HUNG INSIDE: LocalBackupService.restoreAuthData()');
      return false;
    });

    debugPrint('🔐 restoreAuthData: $result');
    return result;
  } catch (e, stackTrace) {
    debugPrint('❌ Error: $e\n$stackTrace');
    return false;
  }
}

// Restore other data in background (non-blocking)
void _restoreOtherDataInBackground() {
  debugPrint('🔄 _restoreOtherDataInBackground() called');

  Future.delayed(const Duration(seconds: 3), () async {
    try {
      debugPrint('');
      debugPrint('========================================');
      debugPrint('🔄 STARTING BACKGROUND DATA RESTORATION');
      debugPrint('========================================');

      // Since auth was restored, we need to restore other data from backup
      // The boxes are already open after auth restore, so we can directly restore
      debugPrint('📥 RESTORING ALL DATA FROM BACKUP FILE...');

      final restored = await LocalBackupService.restoreFromBackup();
      debugPrint('📥 Restore result: $restored');

      if (restored) {
        debugPrint('✅ ✅ ✅ DATA RESTORED SUCCESSFULLY!');
        debugPrint('========================================');

        // Show success message
        Get.snackbar(
          "Data Restored",
          "Your data has been restored from backup!",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      } else {
        debugPrint('⚠️ Backup restore returned false');
        // Try server sync as fallback
        _syncDataFromServer();
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error restoring other data: $e');
      debugPrint('Stack trace: $stackTrace');
      // Try syncing from server as fallback
      _syncDataFromServer();
    }
  });
}

// Sync data from server as fallback
void _syncDataFromServer() {
  debugPrint('🔄 Syncing data from server...');
  try {
    final syncRepo = Get.find<SyncRepository>();

    // Sync vehicles from server
    syncRepo.syncAllCompanyUserVehicles(forceSync: true);

    // Sync arrival terminals from server
    syncRepo.syncCompanyUserArrivalTerminals();

    // Sync commission rules from server
    syncRepo.syncCommissionRules();

    // Note: Departure terminal is set manually by user in Departure settings
    // It cannot be fetched from server automatically
    debugPrint(
        '✅ Server sync initiated for vehicles, arrival terminals, and commission rules');
    debugPrint(
        '⚠️ Note: Departure terminal must be set manually in Departure settings');

    // Show message to user about departure terminal
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.snackbar(
        "Data Sync",
        "Syncing data from server. Please set your departure terminal in Departure settings if not already set.",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    });
  } catch (e) {
    debugPrint('❌ Error syncing from server: $e');
  }
}

// Create backup in background (non-blocking)
void _createBackupInBackground() {
  Future.delayed(const Duration(seconds: 5), () async {
    // First request storage permission
    await LocalBackupService.requestStoragePermission();

    LocalBackupService.createBackup().then((success) {
      if (success) {
        debugPrint('✅ Auto-backup created successfully');
      } else {
        debugPrint('⚠️ Auto-backup failed or no data to backup');
      }
    });
  });
}

class MyApp extends StatefulWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // Create backup when app goes to background
      LocalBackupService.createBackup().then((success) {
        if (success) {
          debugPrint('✅ Backup created when app paused');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Hive.box('appState');
    final isFirstInstall = appState.get('isFirstInstall', defaultValue: true);

    return GetMaterialApp(
      theme: AppTheme.lightTheme,
      // Always start with Sign In page
      initialRoute: AppPages.INITIAL,
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

class SecurityErrorApp extends StatefulWidget {
  final String message;

  const SecurityErrorApp({super.key, required this.message});

  @override
  State<SecurityErrorApp> createState() => _SecurityErrorAppState();
}

class _SecurityErrorAppState extends State<SecurityErrorApp> {
  @override
  void initState() {
    super.initState();
    // Exit the app after showing the error for 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      exit(0);
    });
  }

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
                  style:
                      AppTextStyles.heading1.copyWith(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  widget.message,
                  style: AppTextStyles.body1,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Text(
                  'Application will close in 3 seconds...',
                  style: AppTextStyles.body2.copyWith(color: AppColors.error),
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
