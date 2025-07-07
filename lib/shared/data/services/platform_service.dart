import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

@injectable
class PlatformService {
  static const MethodChannel _channel = MethodChannel('com.mindfence.app/device_control');

  Future<void> requestUsageStatsPermission() async {
    try {
      await _channel.invokeMethod('requestUsageStatsPermission');
    } on PlatformException catch (e) {
      throw Exception('Failed to request usage stats permission: ${e.message}');
    }
  }

  Future<bool> hasUsageStatsPermission() async {
    try {
      final result = await _channel.invokeMethod('hasUsageStatsPermission');
      return result as bool;
    } on PlatformException catch (e) {
      throw Exception('Failed to check usage stats permission: ${e.message}');
    }
  }

  Future<bool> hasAccessibilityPermission() async {
    try {
      final result = await _channel.invokeMethod('hasAccessibilityPermission');
      return result as bool;
    } on PlatformException catch (e) {
      throw Exception('Failed to check accessibility permission: ${e.message}');
    }
  }

  Future<void> requestAccessibilityPermission() async {
    try {
      await _channel.invokeMethod('requestAccessibilityPermission');
    } on PlatformException catch (e) {
      throw Exception('Failed to request accessibility permission: ${e.message}');
    }
  }

  Future<bool> hasDeviceAdminPermission() async {
    try {
      final result = await _channel.invokeMethod('hasDeviceAdminPermission');
      return result as bool;
    } on PlatformException catch (e) {
      throw Exception('Failed to check device admin permission: ${e.message}');
    }
  }

  Future<void> requestDeviceAdminPermission() async {
    try {
      await _channel.invokeMethod('requestDeviceAdminPermission');
    } on PlatformException catch (e) {
      throw Exception('Failed to request device admin permission: ${e.message}');
    }
  }

  Future<void> requestOverlayPermission() async {
    try {
      await _channel.invokeMethod('requestOverlayPermission');
    } on PlatformException catch (e) {
      throw Exception('Failed to request overlay permission: ${e.message}');
    }
  }

  Future<bool> hasOverlayPermission() async {
    try {
      final result = await _channel.invokeMethod('hasOverlayPermission');
      return result as bool;
    } on PlatformException catch (e) {
      throw Exception('Failed to check overlay permission: ${e.message}');
    }
  }

  Future<List<Map<String, dynamic>>> getInstalledApps() async {
    try {
      final result = await _channel.invokeMethod('getInstalledApps');
      return List<Map<String, dynamic>>.from(result);
    } on PlatformException catch (e) {
      throw Exception('Failed to get installed apps: ${e.message}');
    }
  }

  Future<void> startBlocking(List<String> blockedApps) async {
    try {
      await _channel.invokeMethod('startBlocking', {'blockedApps': blockedApps});
    } on PlatformException catch (e) {
      throw Exception('Failed to start blocking: ${e.message}');
    }
  }

  Future<void> stopBlocking() async {
    try {
      await _channel.invokeMethod('stopBlocking');
    } on PlatformException catch (e) {
      throw Exception('Failed to stop blocking: ${e.message}');
    }
  }

  Future<void> updateBlockedApps(List<String> blockedApps) async {
    try {
      await _channel.invokeMethod('updateBlockedApps', {'blockedApps': blockedApps});
    } on PlatformException catch (e) {
      throw Exception('Failed to update blocked apps: ${e.message}');
    }
  }

  Future<bool> isBlocking() async {
    try {
      final result = await _channel.invokeMethod('isBlocking');
      return result as bool;
    } on PlatformException catch (e) {
      throw Exception('Failed to check blocking status: ${e.message}');
    }
  }

  Future<bool> requestVpnPermission() async {
    try {
      final result = await _channel.invokeMethod('requestVpnPermission');
      return result as bool;
    } on PlatformException catch (e) {
      throw Exception('Failed to request VPN permission: ${e.message}');
    }
  }

  Future<void> startVpn(List<String> blockedDomains) async {
    try {
      await _channel.invokeMethod('startVpn', {'blockedDomains': blockedDomains});
    } on PlatformException catch (e) {
      throw Exception('Failed to start VPN: ${e.message}');
    }
  }

  Future<void> stopVpn() async {
    try {
      await _channel.invokeMethod('stopVpn');
    } on PlatformException catch (e) {
      throw Exception('Failed to stop VPN: ${e.message}');
    }
  }
  
  Future<void> requestAllPermissions() async {
    try {
      await _channel.invokeMethod('requestAllPermissions');
    } on PlatformException catch (e) {
      throw Exception('Failed to request all permissions: ${e.message}');
    }
  }
  
  Future<void> openAppSettings() async {
    try {
      await _channel.invokeMethod('openAppSettings');
    } on PlatformException catch (e) {
      throw Exception('Failed to open app settings: ${e.message}');
    }
  }
}