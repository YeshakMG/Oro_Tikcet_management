import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:oro_ticket_app/data/locals/models/service_charge_model.dart';
// Import the UserModel from sign_in module
import 'package:oro_ticket_app/app/modules/sign_in/models/user_model.dart';
import 'package:oro_ticket_app/app/modules/sign_in/services/auth_service.dart';

// Fix the import for Ethiopian datetime
import 'package:ethiopian_datetime/ethiopian_datetime.dart';

// Import SyncRepository
import 'package:oro_ticket_app/data/repositories/sync_repository.dart';

class HomeController extends GetxController {
  final Rx<UserModel?> user = Rx<UserModel?>(null);
  final RxString companyName = ''.obs;
  final RxString companyId = ''.obs;
  final RxString companyPhoneNo = ''.obs;
  final RxString companyLogoUrl = ''.obs; // Add missing property
  final RxDouble serviceChargeToday = 0.0.obs;
  final RxString ethiopianDate = ''.obs;

  final SyncRepository _syncRepository = SyncRepository();

  @override
  void onInit() {
    super.onInit();
    loadUser();
    loadServiceChargeAndDate();
  }

  void loadUser() async {
    final token = await AuthService().getToken();

    if (token == null) {
      debugPrint('No token found — skipping user load');
      return; 
    }

    final loadedUser = await AuthService().getUser();

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

  void loadServiceChargeAndDate() {
    try {
      final box = Hive.box<ServiceChargeModel>('serviceChargeBox');
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final chargesToday = box.values.where((entry) {
        final entryDate = DateTime(
            entry.dateTime.year, entry.dateTime.month, entry.dateTime.day);
        return entry.employeeName == user.value?.fullName && entryDate == today;
      });

      final total = chargesToday.fold<double>(
          0.0, (sum, e) => sum + e.serviceChargeAmount);
      serviceChargeToday.value = total;

      // Use the extension method instead of direct class
      final currentDate = DateTime.now();
      final ethDate = currentDate.convertToEthiopian();
      ethiopianDate.value = "${ethDate.day}/${ethDate.month}/${ethDate.year}";
    } catch (e) {
      serviceChargeToday.value = 0.0;
      ethiopianDate.value = "Unknown Date";
    }
  }

  void resetDashboard() {
    // Reset the service charge for today
    serviceChargeToday.value = 0.0;

    // Reload the Ethiopian date (in case it was showing an error)
    try {
      final currentDate = DateTime.now();
      final ethDate = currentDate.convertToEthiopian();
      ethiopianDate.value = "${ethDate.day}/${ethDate.month}/${ethDate.year}";
    } catch (e) {
      ethiopianDate.value = "Unknown Date";
    }

    // You might want to clear the Hive box entries for today as well
    try {
      final box = Hive.box<ServiceChargeModel>('serviceChargeBox');
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Get entries for today by this employee
      final entriesToRemove = box.values.where((entry) {
        final entryDate = DateTime(
            entry.dateTime.year, entry.dateTime.month, entry.dateTime.day);
        return entry.employeeName == user.value?.fullName && entryDate == today;
      }).toList();

      // Delete these entries
      for (var entry in entriesToRemove) {
        final key = box.keyAt(box.values.toList().indexOf(entry));
        box.delete(key);
      }
    } catch (e) {
      Get.snackbar(
          "Error", "Failed to clear service charge records: ${e.toString()}");
    }
  }

  // --- NEW METHOD ---
  Future<void> syncTrips() async {
    try {
      await _syncRepository.syncTripsToServer();
    } catch (e) {
      throw Exception('Sync failed: $e');
    }
  }
}
