import 'package:equatable/equatable.dart';
import '../../../../shared/domain/entities/blocked_app.dart';

abstract class BlockSetupEvent extends Equatable {
  const BlockSetupEvent();

  @override
  List<Object> get props => [];
}

class LoadInstalledApps extends BlockSetupEvent {}

class LoadMoreApps extends BlockSetupEvent {}

class LoadBlockedApps extends BlockSetupEvent {}

class ToggleAppBlocking extends BlockSetupEvent {
  final BlockedApp app;
  final bool isBlocked;

  const ToggleAppBlocking(this.app, this.isBlocked);

  @override
  List<Object> get props => [app, isBlocked];
}

class RequestPermissions extends BlockSetupEvent {}

class RequestNextPermission extends BlockSetupEvent {
  const RequestNextPermission();
}

class CheckPermissions extends BlockSetupEvent {}

class RequestSpecificPermission extends BlockSetupEvent {
  final String permissionType;

  const RequestSpecificPermission(this.permissionType);

  @override
  List<Object> get props => [permissionType];
}

class StartBlocking extends BlockSetupEvent {}

class StopBlocking extends BlockSetupEvent {}

class FilterApps extends BlockSetupEvent {
  final String query;

  const FilterApps(this.query);

  @override
  List<Object> get props => [query];
}

class RequestAllPermissions extends BlockSetupEvent {
  const RequestAllPermissions();
}

class OpenAppSettings extends BlockSetupEvent {
  const OpenAppSettings();
}