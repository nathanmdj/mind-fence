import 'package:equatable/equatable.dart';
import '../../../../shared/domain/entities/blocked_app.dart';

abstract class BlockSetupState extends Equatable {
  const BlockSetupState();

  @override
  List<Object> get props => [];
}

class BlockSetupInitial extends BlockSetupState {}

class BlockSetupLoading extends BlockSetupState {}

class BlockSetupLoaded extends BlockSetupState {
  final List<BlockedApp> installedApps;
  final List<BlockedApp> blockedApps;
  final List<BlockedApp> filteredApps;
  final bool hasUsageStatsPermission;
  final bool hasAccessibilityPermission;
  final bool hasOverlayPermission;
  final bool isBlocking;
  final String searchQuery;

  const BlockSetupLoaded({
    required this.installedApps,
    required this.blockedApps,
    required this.filteredApps,
    required this.hasUsageStatsPermission,
    required this.hasAccessibilityPermission,
    required this.hasOverlayPermission,
    required this.isBlocking,
    this.searchQuery = '',
  });

  BlockSetupLoaded copyWith({
    List<BlockedApp>? installedApps,
    List<BlockedApp>? blockedApps,
    List<BlockedApp>? filteredApps,
    bool? hasUsageStatsPermission,
    bool? hasAccessibilityPermission,
    bool? hasOverlayPermission,
    bool? isBlocking,
    String? searchQuery,
  }) {
    return BlockSetupLoaded(
      installedApps: installedApps ?? this.installedApps,
      blockedApps: blockedApps ?? this.blockedApps,
      filteredApps: filteredApps ?? this.filteredApps,
      hasUsageStatsPermission: hasUsageStatsPermission ?? this.hasUsageStatsPermission,
      hasAccessibilityPermission: hasAccessibilityPermission ?? this.hasAccessibilityPermission,
      hasOverlayPermission: hasOverlayPermission ?? this.hasOverlayPermission,
      isBlocking: isBlocking ?? this.isBlocking,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object> get props => [
    installedApps,
    blockedApps,
    filteredApps,
    hasUsageStatsPermission,
    hasAccessibilityPermission,
    hasOverlayPermission,
    isBlocking,
    searchQuery,
  ];
}

class BlockSetupError extends BlockSetupState {
  final String message;

  const BlockSetupError(this.message);

  @override
  List<Object> get props => [message];
}

class PermissionRequesting extends BlockSetupState {}

class PermissionGranted extends BlockSetupState {}

class PermissionDenied extends BlockSetupState {
  final String message;

  const PermissionDenied(this.message);

  @override
  List<Object> get props => [message];
}