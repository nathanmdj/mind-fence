import 'package:injectable/injectable.dart';
import '../models/blocked_app_model.dart';
import '../services/platform_service.dart';
import '../services/database_service.dart';

abstract class BlockedAppsDataSource {
  Future<List<BlockedAppModel>> getBlockedApps();
  Future<BlockedAppModel> getBlockedApp(String id);
  Future<void> addBlockedApp(BlockedAppModel app);
  Future<void> updateBlockedApp(BlockedAppModel app);
  Future<void> removeBlockedApp(String id);
  Future<List<BlockedAppModel>> getInstalledApps();
  Future<bool> isAppBlocked(String packageName);
  Future<void> blockApp(String packageName);
  Future<void> unblockApp(String packageName);
  Future<void> startBlocking(List<String> blockedApps);
  Future<void> stopBlocking();
  Future<bool> isBlocking();
}

@Injectable(as: BlockedAppsDataSource)
class BlockedAppsDataSourceImpl implements BlockedAppsDataSource {
  final PlatformService _platformService;
  final DatabaseService _databaseService;

  BlockedAppsDataSourceImpl(this._platformService, this._databaseService);

  @override
  Future<List<BlockedAppModel>> getBlockedApps() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query('blocked_apps');
    return maps.map((map) => BlockedAppModel.fromMap(map)).toList();
  }

  @override
  Future<BlockedAppModel> getBlockedApp(String id) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'blocked_apps',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isEmpty) {
      throw Exception('Blocked app not found with id: $id');
    }
    
    return BlockedAppModel.fromMap(maps.first);
  }

  @override
  Future<void> addBlockedApp(BlockedAppModel app) async {
    final db = await _databaseService.database;
    await db.insert('blocked_apps', app.toMap());
  }

  @override
  Future<void> updateBlockedApp(BlockedAppModel app) async {
    final db = await _databaseService.database;
    await db.update(
      'blocked_apps',
      app.toMap(),
      where: 'id = ?',
      whereArgs: [app.id],
    );
  }

  @override
  Future<void> removeBlockedApp(String id) async {
    final db = await _databaseService.database;
    await db.delete(
      'blocked_apps',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<BlockedAppModel>> getInstalledApps() async {
    final installedApps = await _platformService.getInstalledApps();
    return installedApps.map((app) => BlockedAppModel.fromInstalledApp(app)).toList();
  }

  @override
  Future<bool> isAppBlocked(String packageName) async {
    return await _platformService.isBlocking();
  }

  @override
  Future<void> blockApp(String packageName) async {
    // Get current blocked apps and add the new one
    final blockedApps = await getBlockedApps();
    final blockedPackageNames = blockedApps.map((app) => app.packageName).toList();
    
    if (!blockedPackageNames.contains(packageName)) {
      blockedPackageNames.add(packageName);
      await _platformService.updateBlockedApps(blockedPackageNames);
    }
  }

  @override
  Future<void> unblockApp(String packageName) async {
    // Get current blocked apps and remove the specified one
    final blockedApps = await getBlockedApps();
    final blockedPackageNames = blockedApps.map((app) => app.packageName).toList();
    
    if (blockedPackageNames.contains(packageName)) {
      blockedPackageNames.remove(packageName);
      await _platformService.updateBlockedApps(blockedPackageNames);
    }
  }

  @override
  Future<void> startBlocking(List<String> blockedApps) async {
    await _platformService.startBlocking(blockedApps);
  }

  @override
  Future<void> stopBlocking() async {
    await _platformService.stopBlocking();
  }

  @override
  Future<bool> isBlocking() async {
    return await _platformService.isBlocking();
  }
}