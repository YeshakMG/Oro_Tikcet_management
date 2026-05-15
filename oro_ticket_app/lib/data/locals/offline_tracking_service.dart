import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class OfflineTrackingService {
  static const FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _lastOnlineKey = 'last_online_timestamp';
  static const String _offlineWarningKey = 'offline_warning_shown';
  
  /// Duration threshold for offline lock (5 days)
  static const Duration offlineThreshold = Duration(days: 5);
  
  /// Check if device has been offline for more than 5 days
  static Future<bool> isOfflineForMoreThan72Hours() async {
    try {
      final lastOnlineStr = await _storage.read(key: _lastOnlineKey);
      
      if (lastOnlineStr == null) {
        // First time - assume online, save current time
        await updateLastOnlineTime();
        return false;
      }
      
      final lastOnline = DateTime.parse(lastOnlineStr);
      final now = DateTime.now();
      final difference = now.difference(lastOnline);
      
      return difference > offlineThreshold;
    } catch (e) {
      // If error, allow printing (fail safe)
      return false;
    }
  }
  
  /// Update the last online timestamp
  static Future<void> updateLastOnlineTime() async {
    try {
      final now = DateTime.now().toIso8601String();
      await _storage.write(key: _lastOnlineKey, value: now);
      
      // Reset offline warning flag when back online
      await _storage.delete(key: _offlineWarningKey);
    } catch (e) {
      // Fail silently
    }
  }
  
  /// Check connectivity and update timestamp if online
  static Future<void> checkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      
      if (connectivityResult != ConnectivityResult.none) {
        // Device is online - update timestamp
        await updateLastOnlineTime();
      }
    } catch (e) {
      // Fail silently
    }
  }
  
  /// Start listening to connectivity changes
  static void startConnectivityListener() {
    Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        updateLastOnlineTime();
      }
    });
  }
  
  /// Get remaining offline time before lock (for display)
  static Future<String> getRemainingOfflineTime() async {
    try {
      final lastOnlineStr = await _storage.read(key: _lastOnlineKey);
      
      if (lastOnlineStr == null) {
        return "Online";
      }
      
      final lastOnline = DateTime.parse(lastOnlineStr);
      final now = DateTime.now();
      final difference = now.difference(lastOnline);
      
      if (difference > offlineThreshold) {
        return "Locked - Offline for more than 5 days";
      }
      
      final remaining = offlineThreshold - difference;
      final hours = remaining.inHours;
      final minutes = remaining.inMinutes % 60;
      
      return "${hours}h ${minutes}m remaining";
    } catch (e) {
      return "Online";
    }
  }
  
  /// Check if offline warning has been shown
  static Future<bool> hasShownOfflineWarning() async {
    final value = await _storage.read(key: _offlineWarningKey);
    return value == 'true';
  }
  
  /// Mark offline warning as shown
  static Future<void> setOfflineWarningShown() async {
    await _storage.write(key: _offlineWarningKey, value: 'true');
  }
}
