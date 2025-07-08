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
  final bool hasDeviceAdminPermission;
  final bool hasOverlayPermission;
  final bool isBlocking;
  final String searchQuery;
  final bool isLoadingMore;
  final bool hasMoreApps;
  final int currentPage;
  final int appsPerPage;

  const BlockSetupLoaded({
    required this.installedApps,
    required this.blockedApps,
    required this.filteredApps,
    required this.hasUsageStatsPermission,
    required this.hasAccessibilityPermission,
    required this.hasDeviceAdminPermission,
    required this.hasOverlayPermission,
    required this.isBlocking,
    this.searchQuery = '',
    this.isLoadingMore = false,
    this.hasMoreApps = true,
    this.currentPage = 1,
    this.appsPerPage = 25,
  });

  BlockSetupLoaded copyWith({
    List<BlockedApp>? installedApps,
    List<BlockedApp>? blockedApps,
    List<BlockedApp>? filteredApps,
    bool? hasUsageStatsPermission,
    bool? hasAccessibilityPermission,
    bool? hasDeviceAdminPermission,
    bool? hasOverlayPermission,
    bool? isBlocking,
    String? searchQuery,
    bool? isLoadingMore,
    bool? hasMoreApps,
    int? currentPage,
    int? appsPerPage,
  }) {
    return BlockSetupLoaded(
      installedApps: installedApps ?? this.installedApps,
      blockedApps: blockedApps ?? this.blockedApps,
      filteredApps: filteredApps ?? this.filteredApps,
      hasUsageStatsPermission: hasUsageStatsPermission ?? this.hasUsageStatsPermission,
      hasAccessibilityPermission: hasAccessibilityPermission ?? this.hasAccessibilityPermission,
      hasDeviceAdminPermission: hasDeviceAdminPermission ?? this.hasDeviceAdminPermission,
      hasOverlayPermission: hasOverlayPermission ?? this.hasOverlayPermission,
      isBlocking: isBlocking ?? this.isBlocking,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMoreApps: hasMoreApps ?? this.hasMoreApps,
      currentPage: currentPage ?? this.currentPage,
      appsPerPage: appsPerPage ?? this.appsPerPage,
    );
  }

  @override
  List<Object> get props => [
    installedApps,
    blockedApps,
    filteredApps,
    hasUsageStatsPermission,
    hasAccessibilityPermission,
    hasDeviceAdminPermission,
    hasOverlayPermission,
    isBlocking,
    searchQuery,
    isLoadingMore,
    hasMoreApps,
    currentPage,
    appsPerPage,
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

class PermissionSequentialRequesting extends BlockSetupState {
  final String currentPermission;
  final int currentStep;
  final int totalSteps;

  const PermissionSequentialRequesting({
    required this.currentPermission,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  List<Object> get props => [currentPermission, currentStep, totalSteps];
}

class PermissionSequentialCompleted extends BlockSetupState {}