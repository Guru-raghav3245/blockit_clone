import 'package:flutter/services.dart';

class PlatformChannelHelper {
  static const MethodChannel _channel = MethodChannel('com.blockit/device_admin');

  static Future<bool> startLockTask() async {
    try {
      final result = await _channel.invokeMethod<bool>('startLockTask');
      return result ?? false;
    } on PlatformException catch (e) {
      print('Failed to start lock task: ${e.message}');
      return false;
    }
  }

  static Future<bool> stopLockTask() async {
    try {
      final result = await _channel.invokeMethod<bool>('stopLockTask');
      return result ?? false;
    } on PlatformException catch (e) {
      print('Failed to stop lock task: ${e.message}');
      return false;
    }
  }

  static Future<bool> isDeviceAdminActive() async {
    try {
      final result = await _channel.invokeMethod<bool>('isDeviceAdminActive');
      return result ?? false;
    } on PlatformException catch (e) {
      print('Failed to check device admin: ${e.message}');
      return false;
    }
  }
}