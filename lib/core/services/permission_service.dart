import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../shared/data/services/platform_service.dart';
import 'permission_error_handler.dart';

/// Unified permission service that handles both standard and specialized permissions
@injectable
class PermissionService {
  final PlatformService _platformService;
  final PermissionErrorHandler _errorHandler;
  
  PermissionService(this._platformService, this._errorHandler);

  /// Request all required permissions in optimal order
  Future<PermissionRequestResult> requestAllPermissions() async {
    final results = <PermissionType, PermissionResult>{};
    
    // Request standard permissions first (easier to grant)
    final standardResults = await _requestStandardPermissions();
    results.addAll(standardResults);
    
    // Then request specialized permissions (more complex)
    final specializedResults = await _requestSpecializedPermissions();
    results.addAll(specializedResults);
    
    return PermissionRequestResult(
      results: results,
      allGranted: results.values.every((result) => result.isGranted),
      criticalDenied: _hasCriticalDenied(results),
    );
  }

  /// Check status of all permissions
  Future<Map<PermissionType, PermissionResult>> checkAllPermissionStatus() async {
    final results = <PermissionType, PermissionResult>{};
    
    // Check standard permissions
    final standardResults = await _checkStandardPermissions();
    results.addAll(standardResults);
    
    // Check specialized permissions
    final specializedResults = await _checkSpecializedPermissions();
    results.addAll(specializedResults);
    
    return results;
  }

  /// Request a specific permission
  Future<PermissionResult> requestPermission(PermissionType type) async {
    switch (type) {
      case PermissionType.notification:
        return await _requestNotificationPermission();
      case PermissionType.location:
        return await _requestLocationPermission();
      case PermissionType.usageStats:
        return await _requestUsageStatsPermission();
      case PermissionType.accessibility:
        return await _requestAccessibilityPermission();
      case PermissionType.deviceAdmin:
        return await _requestDeviceAdminPermission();
      case PermissionType.overlay:
        return await _requestOverlayPermission();
      case PermissionType.vpn:
        return await _requestVpnPermission();
    }
  }

  /// Check status of a specific permission
  Future<PermissionResult> checkPermissionStatus(PermissionType type) async {
    switch (type) {
      case PermissionType.notification:
        return await _checkNotificationPermission();
      case PermissionType.location:
        return await _checkLocationPermission();
      case PermissionType.usageStats:
        return await _checkUsageStatsPermission();
      case PermissionType.accessibility:
        return await _checkAccessibilityPermission();
      case PermissionType.deviceAdmin:
        return await _checkDeviceAdminPermission();
      case PermissionType.overlay:
        return await _checkOverlayPermission();
      case PermissionType.vpn:
        return await _checkVpnPermission();
    }
  }

  /// Get user-friendly explanation for a permission
  String getPermissionExplanation(PermissionType type) {
    switch (type) {
      case PermissionType.notification:
        return 'Allow notifications to remind you about focus sessions and blocking status';
      case PermissionType.location:
        return 'Location access helps create location-based blocking rules (optional)';
      case PermissionType.usageStats:
        return 'Required to monitor which apps you use and track your digital wellness';
      case PermissionType.accessibility:
        return 'Essential for detecting when blocked apps are opened and showing blocking screens';
      case PermissionType.deviceAdmin:
        return 'Provides enhanced blocking capabilities and prevents easy bypassing';
      case PermissionType.overlay:
        return 'Required to display blocking screens over other apps';
      case PermissionType.vpn:
        return 'Enables website blocking by routing internet traffic through the app';
    }
  }

  /// Get priority level for a permission
  PermissionPriority getPermissionPriority(PermissionType type) {
    switch (type) {
      case PermissionType.usageStats:
      case PermissionType.accessibility:
        return PermissionPriority.critical;
      case PermissionType.deviceAdmin:
      case PermissionType.overlay:
        return PermissionPriority.high;
      case PermissionType.vpn:
        return PermissionPriority.medium;
      case PermissionType.notification:
      case PermissionType.location:
        return PermissionPriority.low;
    }
  }

  /// Get expected setup time for a permission
  Duration getPermissionSetupTime(PermissionType type) {
    switch (type) {
      case PermissionType.notification:
      case PermissionType.location:
        return Duration(seconds: 5);
      case PermissionType.usageStats:
      case PermissionType.overlay:
        return Duration(seconds: 15);
      case PermissionType.accessibility:
      case PermissionType.deviceAdmin:
        return Duration(seconds: 30);
      case PermissionType.vpn:
        return Duration(seconds: 10);
    }
  }

  /// Open system settings for a specific permission
  Future<void> openPermissionSettings(PermissionType type) async {
    switch (type) {
      case PermissionType.notification:
        await openAppSettings();
        break;
      case PermissionType.location:
        await openAppSettings();
        break;
      case PermissionType.usageStats:
      case PermissionType.accessibility:
      case PermissionType.deviceAdmin:
      case PermissionType.overlay:
      case PermissionType.vpn:
        await _platformService.openAppSettings();
        break;
    }
  }

  // Standard permission methods using permission_handler
  Future<Map<PermissionType, PermissionResult>> _requestStandardPermissions() async {
    // Run standard permission requests in parallel
    final futures = await Future.wait([
      _requestNotificationPermission(),
      _requestLocationPermission(),
    ]);
    
    return {
      PermissionType.notification: futures[0],
      PermissionType.location: futures[1],
    };
  }

  Future<Map<PermissionType, PermissionResult>> _checkStandardPermissions() async {
    // Run standard permission checks in parallel
    final futures = await Future.wait([
      _checkNotificationPermission(),
      _checkLocationPermission(),
    ]);
    
    return {
      PermissionType.notification: futures[0],
      PermissionType.location: futures[1],
    };
  }

  Future<PermissionResult> _requestNotificationPermission() async {
    try {
      final status = await Permission.notification.request();
      return PermissionResult.fromPermissionStatus(status, PermissionType.notification);
    } on PlatformException catch (e) {
      final error = _errorHandler.handlePlatformException(e, PermissionType.notification);
      return PermissionResult.fromPermissionError(error);
    } catch (e) {
      final error = _errorHandler.handleGeneralException(Exception(e.toString()), PermissionType.notification);
      return PermissionResult.fromPermissionError(error);
    }
  }

  Future<PermissionResult> _checkNotificationPermission() async {
    try {
      final status = await Permission.notification.status;
      return PermissionResult.fromPermissionStatus(status, PermissionType.notification);
    } catch (e) {
      return PermissionResult.error(PermissionType.notification, 'Failed to check notification permission: $e');
    }
  }

  Future<PermissionResult> _requestLocationPermission() async {
    try {
      final status = await Permission.location.request();
      return PermissionResult.fromPermissionStatus(status, PermissionType.location);
    } catch (e) {
      return PermissionResult.error(PermissionType.location, 'Failed to request location permission: $e');
    }
  }

  Future<PermissionResult> _checkLocationPermission() async {
    try {
      final status = await Permission.location.status;
      return PermissionResult.fromPermissionStatus(status, PermissionType.location);
    } catch (e) {
      return PermissionResult.error(PermissionType.location, 'Failed to check location permission: $e');
    }
  }

  // Specialized permission methods using custom platform service
  Future<Map<PermissionType, PermissionResult>> _requestSpecializedPermissions() async {
    final results = <PermissionType, PermissionResult>{};
    
    // Request critical permissions first (these require user interaction so should be sequential)
    results[PermissionType.usageStats] = await _requestUsageStatsPermission();
    results[PermissionType.accessibility] = await _requestAccessibilityPermission();
    
    // Request remaining permissions in parallel (these are typically quicker)
    final parallelFutures = await Future.wait([
      _requestDeviceAdminPermission(),
      _requestOverlayPermission(),
    ]);
    
    results[PermissionType.deviceAdmin] = parallelFutures[0];
    results[PermissionType.overlay] = parallelFutures[1];
    
    return results;
  }

  Future<Map<PermissionType, PermissionResult>> _checkSpecializedPermissions() async {
    // Run specialized permission checks in parallel for better performance
    final futures = await Future.wait([
      _checkUsageStatsPermission(),
      _checkAccessibilityPermission(),
      _checkDeviceAdminPermission(),
      _checkOverlayPermission(),
      _checkVpnPermission(),
    ]);
    
    return {
      PermissionType.usageStats: futures[0],
      PermissionType.accessibility: futures[1],
      PermissionType.deviceAdmin: futures[2],
      PermissionType.overlay: futures[3],
      PermissionType.vpn: futures[4],
    };
  }

  Future<PermissionResult> _requestUsageStatsPermission() async {
    try {
      await _platformService.requestUsageStatsPermission();
      // Check if permission was granted
      final granted = await _platformService.hasUsageStatsPermission();
      return PermissionResult.success(PermissionType.usageStats, granted);
    } on PlatformException catch (e) {
      final error = _errorHandler.handlePlatformException(e, PermissionType.usageStats);
      return PermissionResult.fromPermissionError(error);
    } catch (e) {
      final error = _errorHandler.handleGeneralException(Exception(e.toString()), PermissionType.usageStats);
      return PermissionResult.fromPermissionError(error);
    }
  }

  Future<PermissionResult> _checkUsageStatsPermission() async {
    try {
      final granted = await _platformService.hasUsageStatsPermission();
      return PermissionResult.success(PermissionType.usageStats, granted);
    } catch (e) {
      return PermissionResult.error(PermissionType.usageStats, 'Failed to check usage stats permission: $e');
    }
  }

  Future<PermissionResult> _requestAccessibilityPermission() async {
    try {
      await _platformService.requestAccessibilityPermission();
      // Check if permission was granted
      final granted = await _platformService.hasAccessibilityPermission();
      return PermissionResult.success(PermissionType.accessibility, granted);
    } catch (e) {
      return PermissionResult.error(PermissionType.accessibility, 'Failed to request accessibility permission: $e');
    }
  }

  Future<PermissionResult> _checkAccessibilityPermission() async {
    try {
      final granted = await _platformService.hasAccessibilityPermission();
      return PermissionResult.success(PermissionType.accessibility, granted);
    } catch (e) {
      return PermissionResult.error(PermissionType.accessibility, 'Failed to check accessibility permission: $e');
    }
  }

  Future<PermissionResult> _requestDeviceAdminPermission() async {
    try {
      await _platformService.requestDeviceAdminPermission();
      // Check if permission was granted
      final granted = await _platformService.hasDeviceAdminPermission();
      return PermissionResult.success(PermissionType.deviceAdmin, granted);
    } catch (e) {
      return PermissionResult.error(PermissionType.deviceAdmin, 'Failed to request device admin permission: $e');
    }
  }

  Future<PermissionResult> _checkDeviceAdminPermission() async {
    try {
      final granted = await _platformService.hasDeviceAdminPermission();
      return PermissionResult.success(PermissionType.deviceAdmin, granted);
    } catch (e) {
      return PermissionResult.error(PermissionType.deviceAdmin, 'Failed to check device admin permission: $e');
    }
  }

  Future<PermissionResult> _requestOverlayPermission() async {
    try {
      await _platformService.requestOverlayPermission();
      // Check if permission was granted
      final granted = await _platformService.hasOverlayPermission();
      return PermissionResult.success(PermissionType.overlay, granted);
    } catch (e) {
      return PermissionResult.error(PermissionType.overlay, 'Failed to request overlay permission: $e');
    }
  }

  Future<PermissionResult> _checkOverlayPermission() async {
    try {
      final granted = await _platformService.hasOverlayPermission();
      return PermissionResult.success(PermissionType.overlay, granted);
    } catch (e) {
      return PermissionResult.error(PermissionType.overlay, 'Failed to check overlay permission: $e');
    }
  }

  Future<PermissionResult> _requestVpnPermission() async {
    try {
      final granted = await _platformService.requestVpnPermission();
      return PermissionResult.success(PermissionType.vpn, granted);
    } catch (e) {
      return PermissionResult.error(PermissionType.vpn, 'Failed to request VPN permission: $e');
    }
  }

  Future<PermissionResult> _checkVpnPermission() async {
    try {
      // VPN permission doesn't have a direct check method, so we'll try to request it
      final granted = await _platformService.requestVpnPermission();
      return PermissionResult.success(PermissionType.vpn, granted);
    } catch (e) {
      return PermissionResult.error(PermissionType.vpn, 'Failed to check VPN permission: $e');
    }
  }

  bool _hasCriticalDenied(Map<PermissionType, PermissionResult> results) {
    final criticalPermissions = [
      PermissionType.usageStats,
      PermissionType.accessibility,
    ];
    
    return criticalPermissions.any((type) => 
      results[type]?.isDenied == true || results[type]?.isPermanentlyDenied == true
    );
  }
}

/// Types of permissions managed by the service
enum PermissionType {
  notification,
  location,
  usageStats,
  accessibility,
  deviceAdmin,
  overlay,
  vpn,
}

/// Priority levels for permissions
enum PermissionPriority {
  critical,
  high,
  medium,
  low,
}

/// Result of a permission request
class PermissionResult {
  final PermissionType type;
  final bool isGranted;
  final bool isDenied;
  final bool isPermanentlyDenied;
  final bool isRestricted;
  final bool isLimited;
  final String? errorMessage;
  final PermissionError? permissionError;

  PermissionResult({
    required this.type,
    required this.isGranted,
    required this.isDenied,
    required this.isPermanentlyDenied,
    required this.isRestricted,
    required this.isLimited,
    this.errorMessage,
    this.permissionError,
  });

  factory PermissionResult.fromPermissionStatus(PermissionStatus status, PermissionType type) {
    return PermissionResult(
      type: type,
      isGranted: status.isGranted,
      isDenied: status.isDenied,
      isPermanentlyDenied: status.isPermanentlyDenied,
      isRestricted: status.isRestricted,
      isLimited: status.isLimited,
    );
  }

  factory PermissionResult.success(PermissionType type, bool isGranted) {
    return PermissionResult(
      type: type,
      isGranted: isGranted,
      isDenied: !isGranted,
      isPermanentlyDenied: false,
      isRestricted: false,
      isLimited: false,
    );
  }

  factory PermissionResult.error(PermissionType type, String error) {
    return PermissionResult(
      type: type,
      isGranted: false,
      isDenied: true,
      isPermanentlyDenied: false,
      isRestricted: false,
      isLimited: false,
      errorMessage: error,
    );
  }

  factory PermissionResult.fromPermissionError(PermissionError permissionError) {
    return PermissionResult(
      type: permissionError.permissionType,
      isGranted: false,
      isDenied: true,
      isPermanentlyDenied: permissionError.type == PermissionErrorType.permanentlyDenied,
      isRestricted: permissionError.type == PermissionErrorType.restricted,
      isLimited: false,
      errorMessage: permissionError.userFriendlyMessage,
      permissionError: permissionError,
    );
  }

  bool get hasError => errorMessage != null || permissionError != null;
  
  bool get canRetry => permissionError?.canRetry ?? true;
  
  bool get isRecoverable => permissionError?.isRecoverable ?? true;
  
  bool get requiresManualIntervention => permissionError?.requiresManualIntervention ?? false;
}

/// Result of requesting all permissions
class PermissionRequestResult {
  final Map<PermissionType, PermissionResult> results;
  final bool allGranted;
  final bool criticalDenied;

  PermissionRequestResult({
    required this.results,
    required this.allGranted,
    required this.criticalDenied,
  });

  List<PermissionResult> get grantedPermissions => 
    results.values.where((result) => result.isGranted).toList();

  List<PermissionResult> get deniedPermissions => 
    results.values.where((result) => result.isDenied).toList();

  List<PermissionResult> get errorPermissions => 
    results.values.where((result) => result.hasError).toList();
}