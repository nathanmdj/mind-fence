import 'package:injectable/injectable.dart';
import '../datasources/blocked_apps_datasource.dart';
import '../models/blocked_app_model.dart';
import '../../domain/entities/blocked_app.dart';
import '../../domain/repositories/blocked_apps_repository.dart';

@Injectable(as: BlockedAppsRepository)
class BlockedAppsRepositoryImpl implements BlockedAppsRepository {
  final BlockedAppsDataSource _dataSource;

  BlockedAppsRepositoryImpl(this._dataSource);

  @override
  Future<List<BlockedApp>> getBlockedApps() async {
    final models = await _dataSource.getBlockedApps();
    return models.map((model) => model.toDomain()).toList();
  }

  @override
  Future<BlockedApp> getBlockedApp(String id) async {
    final model = await _dataSource.getBlockedApp(id);
    return model.toDomain();
  }

  @override
  Future<void> addBlockedApp(BlockedApp app) async {
    final model = BlockedAppModel.fromDomain(app);
    await _dataSource.addBlockedApp(model);
  }

  @override
  Future<void> updateBlockedApp(BlockedApp app) async {
    final model = BlockedAppModel.fromDomain(app);
    await _dataSource.updateBlockedApp(model);
  }

  @override
  Future<void> removeBlockedApp(String id) async {
    await _dataSource.removeBlockedApp(id);
  }

  @override
  Future<void> toggleAppBlocking(String id) async {
    final app = await getBlockedApp(id);
    final updatedApp = app.copyWith(
      isBlocked: !app.isBlocked,
      lastModified: DateTime.now(),
    );
    await updateBlockedApp(updatedApp);
  }

  @override
  Future<List<BlockedApp>> getInstalledApps() async {
    final models = await _dataSource.getInstalledApps();
    return models.map((model) => model.toDomain()).toList();
  }

  @override
  Future<bool> isAppBlocked(String packageName) async {
    return await _dataSource.isAppBlocked(packageName);
  }

  @override
  Future<void> blockApp(String packageName) async {
    await _dataSource.blockApp(packageName);
  }

  @override
  Future<void> unblockApp(String packageName) async {
    await _dataSource.unblockApp(packageName);
  }

  @override
  Future<void> syncBlockedApps() async {
    // TODO: Implement sync functionality
    // This would handle syncing with cloud storage if needed
  }

  @override
  Future<void> startBlocking(List<String> blockedApps) async {
    await _dataSource.startBlocking(blockedApps);
  }

  @override
  Future<void> stopBlocking() async {
    await _dataSource.stopBlocking();
  }

  @override
  Future<bool> isBlocking() async {
    return await _dataSource.isBlocking();
  }
}