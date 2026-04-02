import 'package:flutter/services.dart';

class PlatformChannelHelper {
  static const MethodChannel _channel = MethodChannel(
    'com.blockit/device_admin',
  );

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
}
