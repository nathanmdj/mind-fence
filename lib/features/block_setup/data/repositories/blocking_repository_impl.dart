import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/blocking_repository.dart';
import '../../../../shared/domain/entities/blocked_app.dart';

@Injectable(as: BlockingRepository)
class BlockingRepositoryImpl implements BlockingRepository {
  final MethodChannel _channel;
  final SharedPreferences _prefs;

  BlockingRepositoryImpl(this._channel, this._prefs);

  @override
  Future<List<BlockedApp>> getInstalledApps() async {
    try {
      final List<dynamic> apps = await _channel.invokeMethod('getInstalledApps');
      return apps.map((app) => BlockedApp(
        id: app['packageName'],
        name: app['appName'],
        packageName: app['packageName'],
        iconPath: '',
        isBlocked: false,
      )).toList();
    } catch (e) {
      throw Exception('Failed to get installed apps: $e');
    }
  }

  @override
  Future<List<BlockedApp>> getBlockedApps() async {
    final String? blockedAppsJson = _prefs.getString('blocked_apps_data');
    if (blockedAppsJson == null) return [];
    
    try {
      // For now, just return the stored package names as BlockedApp objects
      final List<String> packageNames = blockedAppsJson.split(',').where((s) => s.isNotEmpty).toList();
      return packageNames.map((packageName) => BlockedApp(
        id: packageName,
        name: packageName, // We'll need to get the actual name from system
        packageName: packageName,
        iconPath: '',
        isBlocked: true,
      )).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> addBlockedApp(BlockedApp app) async {
    final blockedApps = await getBlockedApps();
    final existingIndex = blockedApps.indexWhere((a) => a.packageName == app.packageName);
    
    if (existingIndex >= 0) {
      blockedApps[existingIndex] = app;
    } else {
      blockedApps.add(app);
    }
    
    await _saveBlockedApps(blockedApps);
  }

  @override
  Future<void> removeBlockedApp(String packageName) async {
    final blockedApps = await getBlockedApps();
    blockedApps.removeWhere((app) => app.packageName == packageName);
    await _saveBlockedApps(blockedApps);
  }

  @override
  Future<void> updateBlockedApp(BlockedApp app) async {
    await addBlockedApp(app);
  }

  @override
  Future<void> startBlocking(List<String> packageNames) async {
    try {
      await _channel.invokeMethod('startBlocking', {'blockedApps': packageNames});
    } catch (e) {
      throw Exception('Failed to start blocking: $e');
    }
  }

  @override
  Future<void> stopBlocking() async {
    try {
      await _channel.invokeMethod('stopBlocking');
    } catch (e) {
      throw Exception('Failed to stop blocking: $e');
    }
  }

  @override
  Future<bool> isBlocking() async {
    try {
      return await _channel.invokeMethod('isBlocking');
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> updateBlockedApps(List<String> packageNames) async {
    try {
      await _channel.invokeMethod('updateBlockedApps', {'blockedApps': packageNames});
    } catch (e) {
      throw Exception('Failed to update blocked apps: $e');
    }
  }

  @override
  Future<bool> hasUsageStatsPermission() async {
    try {
      return await _channel.invokeMethod('hasUsageStatsPermission');
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> requestUsageStatsPermission() async {
    try {
      await _channel.invokeMethod('requestUsageStatsPermission');
    } catch (e) {
      throw Exception('Failed to request usage stats permission: $e');
    }
  }

  @override
  Future<bool> hasAccessibilityPermission() async {
    try {
      return await _channel.invokeMethod('hasAccessibilityPermission');
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> requestAccessibilityPermission() async {
    try {
      await _channel.invokeMethod('requestAccessibilityPermission');
    } catch (e) {
      throw Exception('Failed to request accessibility permission: $e');
    }
  }

  @override
  Future<void> requestDeviceAdminPermission() async {
    try {
      await _channel.invokeMethod('requestDeviceAdminPermission');
    } catch (e) {
      throw Exception('Failed to request device admin permission: $e');
    }
  }

  @override
  Future<void> requestOverlayPermission() async {
    try {
      await _channel.invokeMethod('requestOverlayPermission');
    } catch (e) {
      throw Exception('Failed to request overlay permission: $e');
    }
  }

  @override
  Future<bool> hasOverlayPermission() async {
    try {
      return await _channel.invokeMethod('hasOverlayPermission');
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> requestVpnPermission() async {
    try {
      return await _channel.invokeMethod('requestVpnPermission');
    } catch (e) {
      return false;
    }
  }

  Future<void> _saveBlockedApps(List<BlockedApp> apps) async {
    final packageNames = apps.map((app) => app.packageName).toList();
    await _prefs.setString('blocked_apps_data', packageNames.join(','));
  }
}