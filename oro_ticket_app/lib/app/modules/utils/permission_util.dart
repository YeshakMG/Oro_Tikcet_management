// lib/utils/permission_util.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> requestBluetoothPermissions() async {
  // Request Bluetooth permissions for Android 12+ (API 31+)
  
  // Check and request bluetooth permission
  var bluetoothStatus = await Permission.bluetooth.status;
  if (bluetoothStatus.isDenied) {
    bluetoothStatus = await Permission.bluetooth.request();
  }
  
  // Check and request bluetoothScan permission
  var bluetoothScanStatus = await Permission.bluetoothScan.status;
  if (bluetoothScanStatus.isDenied) {
    bluetoothScanStatus = await Permission.bluetoothScan.request();
  }
  
  // Check and request bluetoothConnect permission
  var bluetoothConnectStatus = await Permission.bluetoothConnect.status;
  if (bluetoothConnectStatus.isDenied) {
    bluetoothConnectStatus = await Permission.bluetoothConnect.request();
  }
  
  // Check and request location permission (required for Bluetooth scanning on older Android versions)
  var locationStatus = await Permission.location.status;
  if (locationStatus.isDenied) {
    locationStatus = await Permission.location.request();
  }
  
  // Check if any permissions are permanently denied
  if (bluetoothStatus.isPermanentlyDenied || 
      bluetoothScanStatus.isPermanentlyDenied || 
      bluetoothConnectStatus.isPermanentlyDenied ||
      locationStatus.isPermanentlyDenied) {
    
    // Show dialog to guide user to settings
    Get.dialog(
      AlertDialog(
        title: Text('Permission Required'),
        content: Text(
          'Bluetooth and Location permissions are required for printing tickets. '
          'Please enable them in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              openAppSettings();
            },
            child: Text('Open Settings'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
}
