import '../entities/blocked_app.dart';

abstract class BlockedAppsRepository {
  Future<List<BlockedApp>> getBlockedApps();
  Future<BlockedApp> getBlockedApp(String id);
  Future<void> addBlockedApp(BlockedApp app);
  Future<void> updateBlockedApp(BlockedApp app);
  Future<void> removeBlockedApp(String id);
  Future<void> toggleAppBlocking(String id);
  Future<List<BlockedApp>> getInstalledApps();
  Future<bool> isAppBlocked(String packageName);
  Future<void> blockApp(String packageName);
  Future<void> unblockApp(String packageName);
  Future<void> syncBlockedApps();
  Future<void> startBlocking(List<String> blockedApps);
  Future<void> stopBlocking();
  Future<bool> isBlocking();
}