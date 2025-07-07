import '../../../../shared/domain/entities/blocked_app.dart';

abstract class BlockingRepository {
  Future<List<BlockedApp>> getInstalledApps();
  Future<List<BlockedApp>> getBlockedApps();
  Future<void> addBlockedApp(BlockedApp app);
  Future<void> removeBlockedApp(String packageName);
  Future<void> updateBlockedApp(BlockedApp app);
  Future<void> startBlocking(List<String> packageNames);
  Future<void> stopBlocking();
  Future<bool> isBlocking();
  Future<void> updateBlockedApps(List<String> packageNames);
  
  // Permission methods
  Future<bool> hasUsageStatsPermission();
  Future<void> requestUsageStatsPermission();
  Future<bool> hasAccessibilityPermission();
  Future<void> requestAccessibilityPermission();
  Future<bool> hasDeviceAdminPermission();
  Future<void> requestDeviceAdminPermission();
  Future<void> requestOverlayPermission();
  Future<bool> hasOverlayPermission();
  Future<bool> requestVpnPermission();
  Future<void> requestAllPermissions();
  Future<void> openAppSettings();
}