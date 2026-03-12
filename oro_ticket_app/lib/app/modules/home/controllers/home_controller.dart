import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:oro_ticket_app/core/constants/colors.dart';
import 'package:oro_ticket_app/data/locals/models/service_charge_model.dart';

import 'package:oro_ticket_app/data/locals/models/user_model.dart';
import 'package:oro_ticket_app/app/modules/sign_in/services/auth_service.dart';
import 'package:oro_ticket_app/data/repositories/sync_repository.dart';
import 'package:oro_ticket_app/widgets/dashboard_card.dart';
import 'package:oro_ticket_app/data/locals/hive_boxes.dart'; // Import DashboardController

// Fix the import for Ethiopian datetime
import 'package:ethiopian_datetime/ethiopian_datetime.dart';

class HomeController extends GetxController {
  final Rx<UserModel?> user = Rx<UserModel?>(null);
  final RxString companyName = ''.obs;
  final RxString companyId = ''.obs;
  final RxString companyLogoUrl = ''.obs; // Add missing property
  final RxDouble serviceChargeToday = 0.0.obs;
  final RxString ethiopianDate = ''.obs;
  final RxString serviceChargeText = ''.obs;
  final RxString companyPhoneNo = ''.obs;
  final RxBool isDashboardReset = false.obs;
  final SyncRepository _syncRepository = SyncRepository();

  // Get the AuthService instance from GetX
  AuthService get _authService => Get.find<AuthService>();

  @override
  void onInit() {
    super.onInit();
    loadUser();
    loadTodayServiceCharge();
    updateEthiopianDate();
  }

  void loadUser() async {
    final token = await _authService.getToken();

    if (token == null) {
      debugPrint('No token found — skipping user load');
      return;
    }

    final loadedUser = await _authService.getUser();

    if (loadedUser != null && loadedUser.companyName != null) {
      user.value = loadedUser;
      companyName.value = loadedUser.companyName!;
      companyLogoUrl.value = loadedUser.logoUrl ?? '';
      companyId.value = loadedUser.companyId;
      companyPhoneNo.value = loadedUser.companyPhoneNo ?? '';
    } else {
      Get.snackbar("Error", "User must have valid company info");
    }
  }

  Future<void> loadTodayServiceCharge() async {
    try {
      final box = await HiveBoxes.getBox<ServiceChargeModel>(HiveBoxes.serviceChargeBox);

      // Get the first entry if available
      final entry = box.isNotEmpty ? box.getAt(0) : null;

      if (entry != null) {
        serviceChargeToday.value = entry.serviceChargeAmount;
      } else {
        serviceChargeToday.value = 0.0;
      }
    } catch (e) {
      print("Error loading service charge: $e");
      serviceChargeToday.value = 0.0;
    }
  }

  void updateEthiopianDate() {
    final now = DateTime.now();
    final ethDate = now.convertToEthiopian();
    ethiopianDate.value =
        "${ethDate.day.toString().padLeft(2, '0')}-${ethDate.month.toString().padLeft(2, '0')}-${ethDate.year}";
  }

  void addOrUpdateServiceCharge({
    required double baseCharge,
    required int seatCount,
    required String departureTerminal,
  }) async {
    try {
      final box = await HiveBoxes.getBox<ServiceChargeModel>(HiveBoxes.serviceChargeBox);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final currentUserId = user.value?.id ?? "Unknown";
      final newChargeAmount = baseCharge * seatCount;

      // Find existing service charge entry for today and user
      ServiceChargeModel? existingEntry;
      try {
        existingEntry = box.values.firstWhere((entry) {
          final entryDate = DateTime(
              entry.dateTime.year, entry.dateTime.month, entry.dateTime.day);
          return entry.employeeId == currentUserId && entryDate == today;
        });
      } catch (_) {
        existingEntry = null;
      }

      if (existingEntry != null) {
        // Update existing entry
        final index = box.values.toList().indexOf(existingEntry);
        final key = box.keyAt(index);

        final updatedEntry = ServiceChargeModel(
          departureTerminal: existingEntry.departureTerminal,
          dateTime: existingEntry.dateTime,
          serviceChargeAmount:
              existingEntry.serviceChargeAmount + newChargeAmount,
          employeeId: existingEntry.employeeId,
          companyId: existingEntry.companyId, 
          employeeName: user.value?.fullName ?? '',
        );

        await box.put(key, updatedEntry);
        print(
            "✅ Service charge updated. New total: ${updatedEntry.serviceChargeAmount}");
      } else {
        // Add new entry
        final newEntry = ServiceChargeModel(
          departureTerminal: departureTerminal,
          dateTime: now,
          serviceChargeAmount: newChargeAmount,
          employeeId: currentUserId,
          companyId: user.value?.companyId ?? "Unknown", 
          employeeName: user.value?.fullName ?? '',
        );

        await box.add(newEntry);
        print("✅ New service charge added: $newChargeAmount");
      }

      // Reload today's total after update
      await loadTodayServiceCharge();
    } catch (e) {
      print("❌ Failed to add/update service charge: $e");
    }
  }

  // Sync trips and return count
  Future<int> syncTrips() async {
    try {
      // Repository will show the snackbar with appropriate message
      final count = await _syncRepository.syncTripsToServer();
      return count;
    } catch (e) {
      // Repository already shows error snackbar, but we can add a fallback
      Get.snackbar(
        "Error",
        "Failed to sync data: $e",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: AppColors.background,
        duration: const Duration(seconds: 4),
      );
      rethrow;
    }
  }

  Future<int> syncServiceCharge() async {
    try {
      // Repository will show the snackbar with appropriate message
      final count = await _syncRepository.syncServiceChargeToServer();
      return count;
    } catch (e) {
      // Repository already shows error snackbar, but we can add a fallback
      Get.snackbar("Error", "Failed to sync service charge: $e",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: AppColors.background,
          duration: const Duration(seconds: 4));
      rethrow;
    }
  }

  void resetDashboard() {
    serviceChargeToday.value = 0.0;
    isDashboardReset.value = true;
    
    // Reset DashboardController values if it exists
    if (Get.isRegistered<DashboardController>()) {
      final dashboardController = Get.find<DashboardController>();
      dashboardController.ticketsSoldToday.value = 0;
      dashboardController.revenueToday.value = 0.0;
      dashboardController.dailyGrowth.value = 0.0;
      dashboardController.totalServiceCharge.value = 0.0;
      dashboardController.numberofVehicles.value = 0;
    }
  }

  void refreshDashboard() {
    loadUser();
    loadTodayServiceCharge();
    updateEthiopianDate();
  }
}
