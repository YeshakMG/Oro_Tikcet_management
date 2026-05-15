import 'package:get/get.dart';
import 'package:oro_ticket_app/data/locals/backup_service.dart';

class BackupController extends GetxController {
  RxBool isLoading = false.obs;
  RxMap<String, int> unsyncedCounts = <String, int>{}.obs;
  RxBool hasUnsyncedData = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadUnsyncedDataCounts();
  }

  Future<void> loadUnsyncedDataCounts() async {
    try {
      final counts = await BackupService.getUnsyncedCount();
      unsyncedCounts.value = counts;
      hasUnsyncedData.value = await BackupService.hasUnsyncedData();
    } catch (e) {
      print('Error loading unsynced data counts: $e');
    }
  }

  Future<void> exportAndShareBackup() async {
    isLoading.value = true;
    try {
      await BackupService.exportAndShare();
      // Refresh counts after export
      await loadUnsyncedDataCounts();
    } catch (e) {
      print('Error exporting backup: $e');
    } finally {
      isLoading.value = false;
    }
  }

  String getDataSummaryText() {
    final trips = unsyncedCounts['trips'] ?? 0;
    final serviceCharges = unsyncedCounts['serviceCharges'] ?? 0;
    final total = unsyncedCounts['total'] ?? 0;

    if (total == 0) {
      return 'No unsynced data available for backup.';
    }

    return 'Found $total records to backup:\n'
           '• $trips trip records\n'
           '• $serviceCharges service charge records';
  }
}