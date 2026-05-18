// lib/data/repositories/enhanced_sync_repository.dart
import 'dart:async';
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:oro_ticket_app/app/modules/sign_in/services/auth_service.dart';
import 'package:oro_ticket_app/data/locals/hive_boxes.dart';
import 'package:oro_ticket_app/data/locals/models/trip_model.dart';
import 'package:oro_ticket_app/data/locals/models/service_charge_model.dart';
import 'package:oro_ticket_app/data/locals/service/connectivity_service.dart';
import 'package:oro_ticket_app/data/locals/service/sync_queue_service.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnhancedSyncRepository {
  final String baseUrl = dotenv.env['API_BASE_URL'] ?? '';
  ConnectivityService get _connectivityService =>
      Get.find<ConnectivityService>();
  final SyncQueueService _syncQueueService = SyncQueueService();

  Timer? _periodicSyncTimer;

  void startPeriodicSync({Duration interval = const Duration(minutes: 5)}) {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = Timer.periodic(interval, (_) => _trySyncPendingData());

    ever(_connectivityService.isConnected, (connected) {
      if (connected) {
        print('🌐 Connectivity restored, attempting to sync pending data...');
        _trySyncPendingData();
      }
    });
  }

  void stopPeriodicSync() {
    _periodicSyncTimer?.cancel();
  }

  Future<void> _trySyncPendingData() async {
    if (!_connectivityService.isConnected.value) {
      print('📴 Device is offline, skipping sync');
      return;
    }

    final pendingItems = await _syncQueueService.getPendingItems();
    if (pendingItems.isEmpty) {
      print('✅ No pending items to sync');
      return;
    }

    print('🔄 Attempting to sync ${pendingItems.length} pending items...');

    for (final item in pendingItems) {
      try {
        final success = item.type == 'trip'
            ? await _syncTrip(item.data)
            : await _syncServiceCharge(item.data);

        if (success) {
          await _syncQueueService.removeFromQueue(item.id);
          print('✅ Successfully synced ${item.type} (${item.id})');
        } else {
          await _syncQueueService.incrementRetry(item.id);
          print('⚠️ Failed to sync ${item.type} (${item.id})');
        }
      } catch (e) {
        await _syncQueueService.incrementRetry(item.id);
        print('❌ Error syncing ${item.type} (${item.id}): $e');
      }
    }

    final remainingSize = await _syncQueueService.queueSize;
    if (remainingSize > 0) {
      print('📦 Sync completed. $remainingSize items remaining in queue');
    } else {
      print('🎉 All pending items synced successfully!');
    }
  }

  Future<bool> _syncTrip(Map<String, dynamic> tripData) async {
    try {
      final authService = Get.find<AuthService>();
      final token = await authService.getToken();

      if (token == null) {
        print('❌ No auth token available');
        return false;
      }

      final response = await http
          .post(
            Uri.parse('$baseUrl/trips'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(tripData),
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('❌ Trip sync error: $e');
      return false;
    }
  }

  // Sync a single service charge to server
  Future<bool> _syncServiceCharge(Map<String, dynamic> chargeData) async {
    try {
      final authService = Get.find<AuthService>();
      final token = await authService.getToken();

      if (token == null) {
        print('❌ No auth token available');
        return false;
      }

      final response = await http
          .post(
            Uri.parse('$baseUrl/service-charges'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(chargeData),
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('❌ Service charge sync error: $e');
      return false;
    }
  }

  Future<void> saveDataWithSync({
    required TripModel trip,
    required ServiceChargeModel serviceCharge,
  }) async {
    // Always save to Hive first for immediate data persistence
    await _saveToHive(trip, serviceCharge);

    // Check connectivity
    if (_connectivityService.isConnected.value) {
      print('🌐 Online - Attempting immediate server sync');

      // Try to sync immediately
      final tripSuccess = await _syncTrip(trip.toJson());
      final chargeSuccess = await _syncServiceCharge(serviceCharge.toJson());

      if (tripSuccess) {
        print('✅ Trip synced successfully');
        // Mark trip as synced in Hive using its key
        trip.isSynced = true;
        await trip.save(); // HiveObject.save() method
      } else {
        print('⚠️ Trip sync failed, queued for retry');
        await _queueForRetry('trip', trip.toJson());
      }

      if (chargeSuccess) {
        print('✅ Service charge synced successfully');
        // Remove from Hive if synced
        final chargeBox =
            Hive.box<ServiceChargeModel>(HiveBoxes.serviceChargeBox);
        // Find and remove the synced charge
        final keys = chargeBox.keys.toList();
        for (final key in keys) {
          final charge = chargeBox.get(key);
          if (charge != null && charge.employeeId == serviceCharge.employeeId) {
            await chargeBox.delete(key);
            print('🗑️ Removed synced service charge from local storage');
            break;
          }
        }
      } else {
        print('⚠️ Service charge sync failed, queued for retry');
        await _queueForRetry('service_charge', serviceCharge.toJson());
      }
    } else {
      print('📴 Offline - Data saved locally, will sync when online');

      // Queue both for later sync with unique IDs
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      await _queueForRetry('trip', {
        ...trip.toJson(),
        '_local_key': trip.key.toString(), // Store Hive key for reference
        '_timestamp': timestamp,
      });
      await _queueForRetry('service_charge', {
        ...serviceCharge.toJson(),
        '_local_key':
            serviceCharge.key.toString(), // Store Hive key for reference
        '_timestamp': timestamp,
      });
    }

    _showSyncNotification(
      isOnline: _connectivityService.isConnected.value,
    );
  }

  Future<void> _queueForRetry(String type, Map<String, dynamic> data) async {
    final item = SyncQueueItem(
      id: '${type}_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      data: data,
      createdAt: DateTime.now(),
    );

    await _syncQueueService.addToQueue(item);
  }

  // Save to Hive (your existing local storage)
  Future<void> _saveToHive(
      TripModel trip, ServiceChargeModel serviceCharge) async {
    // Save trip
    final tripBox = Hive.box<TripModel>(HiveBoxes.tripBox);
    final tripKey = await tripBox.add(trip);
    print('💾 Trip saved locally with key: $tripKey');

    // Save service charge
    final chargeBox = Hive.box<ServiceChargeModel>(HiveBoxes.serviceChargeBox);

    // Check for existing charge and update it
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final existingEntry = chargeBox.values.firstWhereOrNull((entry) {
      final entryDate = DateTime(
          entry.dateTime.year, entry.dateTime.month, entry.dateTime.day);
      return entry.departureTerminal == trip.departureTerminalId &&
          entry.employeeId == trip.employeeId &&
          entryDate == today;
    });

    if (existingEntry != null) {
      existingEntry.serviceChargeAmount += serviceCharge.serviceChargeAmount;
      await existingEntry.save();
      print(
          '💾 Updated existing service charge for employee ${trip.employeeId}');
    } else {
      final chargeKey = await chargeBox.add(serviceCharge);
      print('💾 Service charge saved locally with key: $chargeKey');
    }
  }

  // Show notification to user
  void _showSyncNotification({required bool isOnline}) {
    if (isOnline) {
      Get.snackbar(
        "Saved & Synced",
        "Data saved locally and synced to server",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withValues(alpha: 0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } else {
      Get.snackbar(
        "Saved Offline",
        "Data saved locally. Will sync when online.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withValues(alpha: 0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<int> get pendingSyncCount => _syncQueueService.queueSize;
}
