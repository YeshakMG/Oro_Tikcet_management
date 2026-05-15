import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DeviceSecurityChecker {
  /// Check if the app is running on an emulator, rooted device, or simulator
  static Future<bool> isDeviceSecure() async {
    if (kIsWeb) {
      // Web platform - can't detect devices
      return true;
    }
    
    if (Platform.isAndroid) {
      return await _checkAndroidDevice();
    } else if (Platform.isIOS) {
      return await _checkIOSDevice();
    }
    
    return true;
  }
  
  /// Check Android device security
  static Future<bool> _checkAndroidDevice() async {
    // Check for emulator
    if (await _isEmulator()) {
      _blockedReason = 'This app cannot run on Android emulators.\n\nPlease install the app on a physical Android device.';
      return false;
    }
    
    // Check for rooted device
    if (await _isRooted()) {
      _blockedReason = 'This app cannot run on rooted Android devices.\n\nFor security reasons, this app requires a non-rooted device.\n\nPlease install the app on a secure physical device.';
      return false;
    }
    
    return true;
  }
  
  /// Check iOS device security
  static Future<bool> _checkIOSDevice() async {
    // Check for simulator
    if (await _isSimulator()) {
      _blockedReason = 'This app cannot run on iOS simulator.\n\nPlease install the app on a physical iOS device.';
      return false;
    }
    
    return true;
  }
  
  // Store the blocked reason for display
  static String _blockedReason = '';
  
  static String get blockedReason => _blockedReason;
  
  /// Check if running on Android emulator
  static Future<bool> _isEmulator() async {
    try {
      // Check common emulator indicators
      final emulatorPaths = [
        '/system/lib/libc_malloc_debug_leak.so',
        '/system/lib64/libc_malloc_debug_leak.so',
        '/system/bin/failsafe/su',
        '/sbin/su',
      ];
      
      for (final path in emulatorPaths) {
        if (await File(path).exists()) {
          return true;
        }
      }
      
      // Check Android properties
      final result = await Process.run('getprop', ['ro.kernel.qemu']);
      if (result.stdout.toString().trim() == '1') {
        return true;
      }
      
      // Check for emulator-specific files
      if (Platform.isAndroid) {
        // Additional emulator detection
        final qemuResult = await Process.run('getprop', ['ro.hardware']);
        final hardware = qemuResult.stdout.toString().toLowerCase();
        if (hardware.contains('goldfish') || hardware.contains('ranchu')) {
          return true;
        }
      }
      
      return false;
    } catch (e) {
      debugPrint('Error checking emulator: $e');
      return false;
    }
  }
  
  /// Check if Android device is rooted
  static Future<bool> _isRooted() async {
    try {
      // Check for common root-related files
      final rootFiles = [
        '/system/app/Superuser.apk',
        '/system/xbin/su',
        '/system/bin/su',
        '/sbin/su',
        '/system/sd/xbin/su',
        '/system/bin/failsafe/su',
        '/data/local/xbin/su',
        '/data/local/bin/su',
        '/system/lib/libsupol.so',
        '/system/lib64/libsupol.so',
        '/sbin',
        '/system/bin',
        '/system/xbin',
        '/vendor/bin',
        '/data/local',
      ];
      
      for (final path in rootFiles) {
        if (await File(path).exists() || await Directory(path).exists()) {
          // Additional check - verify if su binary actually works
          try {
            final result = await Process.run('which', ['su']);
            if (result.exitCode == 0) {
              return true;
            }
          } catch (_) {
            // Continue checking
          }
        }
      }
      
      // Check for root management apps
      final rootApps = [
        'com.topjohnwu.magisk',
        'com.noshufou.android.su',
        'com.noshufou.android.su.elite',
        'eu.chainfire.supersu',
        'com.koushikdutta.superuser',
        'com.thirdparty.superuser',
        'com.yellowes.su',
        'com.kingroot.kinguser',
        'com.kingo.root',
        'com.smedialink.oneclickroot',
        'com.diamondteam.superr',
      ];
      
      // Check for dangerous props
      final dangerousProps = [
        'ro.debuggable',
        'ro.secure',
      ];
      
      for (final prop in dangerousProps) {
        try {
          final result = await Process.run('getprop', [prop]);
          final value = result.stdout.toString().trim();
          if (prop == 'ro.debuggable' && value == '1') {
            return true;
          }
          if (prop == 'ro.secure' && value == '0') {
            return true;
          }
        } catch (_) {
          // Continue checking
        }
      }
      
      return false;
    } catch (e) {
      debugPrint('Error checking rooted: $e');
      return false;
    }
  }
  
  /// Check if running on iOS simulator
  static Future<bool> _isSimulator() async {
    try {
      // On iOS, we can check the platform
      if (Platform.isIOS) {
        // Check if running on simulator using UIDevice
        final result = await Process.run('uname', ['-a']);
        final uname = result.stdout.toString().toLowerCase();
        if (uname.contains('simulator') || uname.contains('x86_64') || uname.contains('i386')) {
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error checking simulator: $e');
      return false;
    }
  }
  
  /// Show error dialog and exit app
  static void showSecurityErrorAndExit(String message) {
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.security,
                  color: Colors.orange,
                  size: 80,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Security Check',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        'Why is this happening?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'This app contains sensitive ticket data and requires a secure device to protect your information.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}
