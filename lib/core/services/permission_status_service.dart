import 'dart:async';
import 'dart:collection';
import 'package:injectable/injectable.dart';
import 'permission_service.dart';
import 'app_lifecycle_service.dart';

/// Service that provides real-time permission status updates
@injectable
class PermissionStatusService {
  final PermissionService _permissionService;
  final AppLifecycleService _lifecycleService;
  
  // Stream controllers for permission status updates
  final _permissionStatusController = StreamController<Map<PermissionType, PermissionResult>>.broadcast();
  final _individualPermissionController = StreamController<PermissionResult>.broadcast();
  
  // Cache for permission statuses
  final Map<PermissionType, PermissionResult> _permissionCache = {};
  
  // Flag to prevent multiple simultaneous refresh operations
  bool _isRefreshing = false;
  
  // Timer for periodic status checks
  Timer? _periodicCheckTimer;
  
  PermissionStatusService(this._permissionService, this._lifecycleService);
  
  /// Stream of all permission status updates
  Stream<Map<PermissionType, PermissionResult>> get permissionStatusStream => 
    _permissionStatusController.stream;
  
  /// Stream of individual permission status updates
  Stream<PermissionResult> get individualPermissionStream => 
    _individualPermissionController.stream;
  
  /// Get current cached permission statuses
  Map<PermissionType, PermissionResult> get currentPermissionStatuses => 
    UnmodifiableMapView(_permissionCache);
  
  /// Initialize the service
  Future<void> initialize() async {
    // Register for app lifecycle events
    _lifecycleService.addResumeCallback(_onAppResumed);
    
    // Initial permission status check
    await _refreshPermissionStatuses();
    
    // Start periodic status checks (every 30 seconds when app is active)
    _startPeriodicChecks();
  }
  
  /// Dispose of the service
  void dispose() {
    _lifecycleService.removeResumeCallback(_onAppResumed);
    _periodicCheckTimer?.cancel();
    _permissionStatusController.close();
    _individualPermissionController.close();
  }
  
  /// Manually refresh permission statuses
  Future<void> refreshPermissionStatuses() async {
    await _refreshPermissionStatuses();
  }
  
  /// Get status of a specific permission with caching
  Future<PermissionResult> getPermissionStatus(PermissionType type) async {
    // Return cached result if available and recent
    if (_permissionCache.containsKey(type)) {
      return _permissionCache[type]!;
    }
    
    // Fetch fresh status
    final result = await _permissionService.checkPermissionStatus(type);
    _permissionCache[type] = result;
    
    // Notify listeners
    _individualPermissionController.add(result);
    
    return result;
  }
  
  /// Request a permission and update status
  Future<PermissionResult> requestPermission(PermissionType type) async {
    final result = await _permissionService.requestPermission(type);
    
    // Update cache
    _permissionCache[type] = result;
    
    // Notify listeners
    _individualPermissionController.add(result);
    _permissionStatusController.add(UnmodifiableMapView(_permissionCache));
    
    return result;
  }
  
  /// Check if all critical permissions are granted
  bool get areCriticalPermissionsGranted {
    final criticalPermissions = [
      PermissionType.usageStats,
      PermissionType.accessibility,
    ];
    
    return criticalPermissions.every((type) => 
      _permissionCache[type]?.isGranted == true
    );
  }
  
  /// Check if any permissions are pending
  bool get hasPermissionsPending {
    return _permissionCache.values.any((result) => result.isDenied && !result.isPermanentlyDenied);
  }
  
  /// Get list of permissions that need attention
  List<PermissionType> get permissionsNeedingAttention {
    return _permissionCache.entries
        .where((entry) => !entry.value.isGranted)
        .map((entry) => entry.key)
        .toList();
  }
  
  /// Get setup progress as percentage
  double get setupProgress {
    if (_permissionCache.isEmpty) return 0.0;
    
    final grantedCount = _permissionCache.values.where((result) => result.isGranted).length;
    return grantedCount / _permissionCache.length;
  }
  
  /// Check all permission statuses (for compatibility with existing code)
  Future<Map<PermissionType, PermissionResult>> checkAllPermissionStatus() async {
    final statuses = await _permissionService.checkAllPermissionStatus();
    
    // Update cache
    _permissionCache.addAll(statuses);
    
    // Notify listeners
    _permissionStatusController.add(UnmodifiableMapView(_permissionCache));
    
    return statuses;
  }
  
  void _onAppResumed() {
    // Add small delay to ensure system has time to update permission states
    Future.delayed(Duration(milliseconds: 500), () {
      _refreshPermissionStatuses();
    });
  }
  
  Future<void> _refreshPermissionStatuses() async {
    if (_isRefreshing) return;
    
    _isRefreshing = true;
    
    try {
      final statuses = await _permissionService.checkAllPermissionStatus();
      
      // Update cache and check for changes
      bool hasChanges = false;
      
      for (final entry in statuses.entries) {
        final previousResult = _permissionCache[entry.key];
        final newResult = entry.value;
        
        if (previousResult == null || _hasStatusChanged(previousResult, newResult)) {
          _permissionCache[entry.key] = newResult;
          hasChanges = true;
          
          // Notify individual permission listeners
          _individualPermissionController.add(newResult);
        }
      }
      
      // Notify global listeners if there are changes
      if (hasChanges) {
        _permissionStatusController.add(UnmodifiableMapView(_permissionCache));
      }
    } catch (e) {
      // Log error but don't crash
      print('Error refreshing permission statuses: $e');
    } finally {
      _isRefreshing = false;
    }
  }
  
  bool _hasStatusChanged(PermissionResult previous, PermissionResult current) {
    return previous.isGranted != current.isGranted ||
           previous.isDenied != current.isDenied ||
           previous.isPermanentlyDenied != current.isPermanentlyDenied ||
           previous.isRestricted != current.isRestricted ||
           previous.isLimited != current.isLimited;
  }
  
  void _startPeriodicChecks() {
    _periodicCheckTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      // Only check if app is in foreground and not already refreshing
      if (!_isRefreshing) {
        _refreshPermissionStatuses();
      }
    });
  }
}

/// Extension to provide convenience methods for permission results
extension PermissionStatusServiceExtensions on PermissionStatusService {
  /// Check if a specific permission is granted
  bool isPermissionGranted(PermissionType type) {
    return _permissionCache[type]?.isGranted ?? false;
  }
  
  /// Check if a specific permission is denied
  bool isPermissionDenied(PermissionType type) {
    return _permissionCache[type]?.isDenied ?? false;
  }
  
  /// Check if a specific permission is permanently denied
  bool isPermissionPermanentlyDenied(PermissionType type) {
    return _permissionCache[type]?.isPermanentlyDenied ?? false;
  }
  
  /// Get user-friendly status description
  String getStatusDescription(PermissionType type) {
    final result = _permissionCache[type];
    if (result == null) return 'Unknown';
    
    if (result.isGranted) return 'Granted';
    if (result.isPermanentlyDenied) return 'Permanently Denied';
    if (result.isDenied) return 'Denied';
    if (result.isRestricted) return 'Restricted';
    if (result.isLimited) return 'Limited';
    
    return 'Unknown';
  }
}