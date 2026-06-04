import 'package:flutter/services.dart';

class PlatformChannelHelper {
  static const MethodChannel _channel = MethodChannel(
    'com.blockit/device_admin',
  );

  // ================== EXISTING METHODS ==================

  static Future<bool> startLockTask() async {
    try {
      final result = await _channel.invokeMethod<bool>('startLockTask');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> stopLockTask() async {
    try {
      final result = await _channel.invokeMethod<bool>('stopLockTask');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> isDeviceAdminActive() async {
    try {
      final result = await _channel.invokeMethod<bool>('isDeviceAdminActive');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> isAccessibilityServiceEnabled() async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'isAccessibilityServiceEnabled',
      );
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } catch (e) {}
  }

  static Future<void> turnOffScreen() async {
    try {
      await _channel.invokeMethod('turnOffScreen');
    } catch (e) {}
  }

  static Future<void> wakeScreen() async {
    try {
      await _channel.invokeMethod('wakeScreen');
    } catch (e) {}
  }

  // ================== FIXED: BATTERY INFO CHANNEL BRIDGE ==================
  static Future<Map<String, dynamic>> getBatteryInfo() async {
    try {
      final Map? result = await _channel.invokeMethod<Map>('getBatteryInfo');
      if (result != null) {
        return {
          'level': result['level'] as int? ?? -1,
          'isCharging': result['isCharging'] as bool? ?? false,
        };
      }
    } catch (e) {
      print('Error getting battery info: $e');
    }
    return {'level': -1, 'isCharging': false};
  }

  // ================== NEW: INSTAGRAM REELS BLOCKING ==================

  /// Enable or disable Instagram Reels blocking
  static Future<void> enableReelsBlocking(bool enable) async {
    try {
      await _channel.invokeMethod('enableReelsBlocking', {'enable': enable});
    } catch (e) {
      print('Error enabling reels blocking: $e');
    }
  }

  /// Check if Reels blocking is currently enabled
  static Future<bool> isReelsBlockingEnabled() async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'isReelsBlockingEnabled',
      );
      return result ?? false;
    } catch (e) {
      print('Error checking reels blocking status: $e');
      return false;
    }
  }
}
