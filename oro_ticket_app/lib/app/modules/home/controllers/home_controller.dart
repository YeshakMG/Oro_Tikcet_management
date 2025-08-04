import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:oro_ticket_app/data/locals/models/service_charge_model.dart';
// Import the UserModel from sign_in module
import 'package:oro_ticket_app/app/modules/sign_in/models/user_model.dart';
import 'package:oro_ticket_app/app/modules/sign_in/services/auth_service.dart';
import 'package:oro_ticket_app/data/repositories/sync_repository.dart';

// Fix the import for Ethiopian datetime
import 'package:ethiopian_datetime/ethiopian_datetime.dart';

class HomeController extends GetxController {
  final Rx<UserModel?> user = Rx<UserModel?>(null);
  final RxString companyName = ''.obs;
  final RxString companyId = ''.obs;
  final RxString companyLogoUrl = ''.obs;
  final RxDouble serviceChargeToday = 0.0.obs;
  final RxString ethiopianDate = ''.obs;
  final RxString serviceChargeText = ''.obs;
  final SyncRepository _syncRepository = SyncRepository();

  @override
  void onInit() {
    super.onInit();
    loadUser();
    loadTodayServiceCharge();
    updateEthiopianDate();
    
  }

  void loadUser() async {
    final loadedUser = await AuthService().getUser();
    if (loadedUser != null && loadedUser.companyName != null) {
      user.value = loadedUser;
      companyName.value = loadedUser.companyName!;
      companyLogoUrl.value = loadedUser.logoUrl ?? '';
      companyId.value = loadedUser.companyId;
    } else {
      Get.snackbar("Error", "User must have valid company info");
    }
  }

  Future<void> loadTodayServiceCharge() async {
    try {
      final box = Hive.box<ServiceChargeModel>('serviceChargeBox');

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
    ethiopianDate.value = "${ethDate.year}/${ethDate.month.toString().padLeft(2, '0')}/${ethDate.day.toString().padLeft(2, '0')}";
  }

  void addOrUpdateServiceCharge({
    required double baseCharge,
    required int seatCount,
    required String departureTerminal,
  }) async {
    try {
      final box = Hive.box<ServiceChargeModel>('serviceChargeBox');
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final currentUserId = user.value?.id ?? "Unknown";
      final newChargeAmount = baseCharge * seatCount;

      // Find existing service charge entry for today and user
      ServiceChargeModel? existingEntry;
      try {
        existingEntry = box.values.firstWhere((entry) {
          final entryDate = DateTime(entry.dateTime.year, entry.dateTime.month, entry.dateTime.day);
          return entry.employeeName == currentUserId && entryDate == today;
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
          serviceChargeAmount: existingEntry.serviceChargeAmount + newChargeAmount,
          employeeName: existingEntry.employeeName,
          companyId: existingEntry.companyId,
        );

        await box.put(key, updatedEntry);
        print("✅ Service charge updated. New total: ${updatedEntry.serviceChargeAmount}");
      } else {
        // Add new entry
        final newEntry = ServiceChargeModel(
          departureTerminal: departureTerminal,
          dateTime: now,
          serviceChargeAmount: newChargeAmount,
          employeeName: currentUserId,
          companyId: user.value?.companyId ?? "Unknown",
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

  // Dummy placeholder for syncing trips
  Future<void> syncTrips() async {
    try {
      await _syncRepository.syncTripsToServer();
      Get.snackbar("Success", "Data synced successfully");
    } catch (e) {
      Get.snackbar("Error", "Failed to sync data: $e");
      rethrow;
    }
  }
  Future<void> syncServiceCharge() async {
    try {
      await _syncRepository.syncServiceChargeToServer();
      Get.snackbar("Success", "Service charge synced successfully");
    } catch (e) {
      Get.snackbar("Error", "Failed to sync service charge: $e");
      rethrow;
    }
  }

  void resetDashboard() {
    serviceChargeToday.value = 0.0;
    // Reset other dashboard data if any
  }
  void refreshDashboard() {
  loadUser();
  loadTodayServiceCharge();
  updateEthiopianDate();
}

}
