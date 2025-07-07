import 'package:injectable/injectable.dart';
import '../repositories/blocking_repository.dart';

@injectable
class RequestPermissions {
  final BlockingRepository repository;

  RequestPermissions(this.repository);

  Future<bool> hasUsageStatsPermission() async {
    return await repository.hasUsageStatsPermission();
  }

  Future<void> requestUsageStatsPermission() async {
    await repository.requestUsageStatsPermission();
  }

  Future<bool> hasAccessibilityPermission() async {
    return await repository.hasAccessibilityPermission();
  }

  Future<void> requestAccessibilityPermission() async {
    await repository.requestAccessibilityPermission();
  }

  Future<bool> hasDeviceAdminPermission() async {
    return await repository.hasDeviceAdminPermission();
  }

  Future<void> requestDeviceAdminPermission() async {
    await repository.requestDeviceAdminPermission();
  }

  Future<void> requestOverlayPermission() async {
    await repository.requestOverlayPermission();
  }

  Future<bool> hasOverlayPermission() async {
    return await repository.hasOverlayPermission();
  }

  Future<bool> requestVpnPermission() async {
    return await repository.requestVpnPermission();
  }
  
  Future<void> requestAllPermissions() async {
    await repository.requestAllPermissions();
  }
  
  Future<void> openAppSettings() async {
    await repository.openAppSettings();
  }
}