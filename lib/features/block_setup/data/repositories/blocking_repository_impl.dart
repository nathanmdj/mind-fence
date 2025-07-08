import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/blocking_repository.dart';
import '../../../../shared/domain/entities/blocked_app.dart';
import '../../../../shared/data/services/platform_service.dart';

@Injectable(as: BlockingRepository)
class BlockingRepositoryImpl implements BlockingRepository {
  final MethodChannel _channel;
  final SharedPreferences _prefs;
  final PlatformService _platformService;

  static const String _installedAppsKey = 'cached_installed_apps';
  static const String _installedAppsTimestampKey = 'cached_installed_apps_timestamp';
  static const Duration _cacheValidDuration = Duration(hours: 24);

  BlockingRepositoryImpl(this._channel, this._prefs, this._platformService);

  @override
  Future<List<BlockedApp>> getInstalledApps() async {
    try {
      // Check if we have valid cached data
      final cachedApps = await _getCachedInstalledApps();
      if (cachedApps != null) {
        return cachedApps;
      }

      // If no valid cache, fetch fresh data
      return await _fetchAndCacheInstalledApps();
    } catch (e) {
      throw Exception('Failed to get installed apps: $e');
    }
  }

  Future<List<BlockedApp>?> _getCachedInstalledApps() async {
    try {
      final cachedAppsJson = _prefs.getString(_installedAppsKey);
      final cachedTimestamp = _prefs.getInt(_installedAppsTimestampKey);
      
      if (cachedAppsJson == null || cachedTimestamp == null) {
        return null;
      }
      
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(cachedTimestamp);
      final isExpired = DateTime.now().difference(cacheTime) > _cacheValidDuration;
      
      if (isExpired) {
        return null;
      }
      
      final List<dynamic> cachedData = jsonDecode(cachedAppsJson);
      return cachedData.map((app) => BlockedApp(
        id: app['packageName'],
        name: app['appName'],
        packageName: app['packageName'],
        iconPath: app['iconPath'] ?? '',
        isBlocked: false,
      )).toList();
    } catch (e) {
      // If cache is corrupted, return null to trigger fresh fetch
      return null;
    }
  }

  Future<List<BlockedApp>> _fetchAndCacheInstalledApps() async {
    final List<dynamic> apps = await _channel.invokeMethod('getInstalledApps');
    
    // Cache the raw data for future use
    await _prefs.setString(_installedAppsKey, jsonEncode(apps));
    await _prefs.setInt(_installedAppsTimestampKey, DateTime.now().millisecondsSinceEpoch);
    
    return apps.map((app) => BlockedApp(
      id: app['packageName'],
      name: app['appName'],
      packageName: app['packageName'],
      iconPath: app['iconPath'] ?? '',
      isBlocked: false,
    )).toList();
  }

  /// Force refresh the cached installed apps
  Future<List<BlockedApp>> refreshInstalledApps() async {
    try {
      return await _fetchAndCacheInstalledApps();
    } catch (e) {
      throw Exception('Failed to refresh installed apps: $e');
    }
  }

  /// Clear the installed apps cache
  Future<void> clearInstalledAppsCache() async {
    await _prefs.remove(_installedAppsKey);
    await _prefs.remove(_installedAppsTimestampKey);
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
    return await _platformService.hasUsageStatsPermission();
  }

  @override
  Future<void> requestUsageStatsPermission() async {
    await _platformService.requestUsageStatsPermission();
  }

  @override
  Future<bool> hasAccessibilityPermission() async {
    return await _platformService.hasAccessibilityPermission();
  }

  @override
  Future<void> requestAccessibilityPermission() async {
    await _platformService.requestAccessibilityPermission();
  }

  @override
  Future<bool> hasDeviceAdminPermission() async {
    return await _platformService.hasDeviceAdminPermission();
  }

  @override
  Future<void> requestDeviceAdminPermission() async {
    await _platformService.requestDeviceAdminPermission();
  }

  @override
  Future<void> requestOverlayPermission() async {
    await _platformService.requestOverlayPermission();
  }

  @override
  Future<bool> hasOverlayPermission() async {
    return await _platformService.hasOverlayPermission();
  }

  @override
  Future<bool> requestVpnPermission() async {
    return await _platformService.requestVpnPermission();
  }
  
  @override
  Future<void> requestAllPermissions() async {
    await _platformService.requestAllPermissions();
  }
  
  @override
  Future<void> openAppSettings() async {
    await _platformService.openAppSettings();
  }

  Future<void> _saveBlockedApps(List<BlockedApp> apps) async {
    final packageNames = apps.map((app) => app.packageName).toList();
    await _prefs.setString('blocked_apps_data', packageNames.join(','));
  }
}