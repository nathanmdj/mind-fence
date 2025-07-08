import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'block_setup_event.dart';
import 'block_setup_state.dart';
import '../../domain/usecases/get_installed_apps.dart';
import '../../domain/usecases/toggle_app_blocking.dart' as usecases;
import '../../domain/usecases/request_permissions.dart' as usecases;
import '../../domain/repositories/blocking_repository.dart';
import '../../../../shared/domain/entities/blocked_app.dart';
import '../../../../core/services/permission_service.dart';
import '../../../../core/services/permission_status_service.dart';

@injectable
class BlockSetupBloc extends Bloc<BlockSetupEvent, BlockSetupState> {
  final GetInstalledApps _getInstalledApps;
  final usecases.ToggleAppBlocking _toggleAppBlocking;
  final usecases.RequestPermissions _requestPermissions;
  final BlockingRepository _repository;
  final PermissionService _permissionService;
  final PermissionStatusService _permissionStatusService;

  BlockSetupBloc(
    this._getInstalledApps,
    this._toggleAppBlocking,
    this._requestPermissions,
    this._repository,
    this._permissionService,
    this._permissionStatusService,
  ) : super(BlockSetupInitial()) {
    on<LoadInstalledApps>(_onLoadInstalledApps);
    on<LoadMoreApps>(_onLoadMoreApps);
    on<LoadBlockedApps>(_onLoadBlockedApps);
    on<ToggleAppBlocking>(_onToggleAppBlocking);
    on<RequestPermissions>(_onRequestPermissions);
    on<RequestNextPermission>(_onRequestNextPermission);
    on<RequestSpecificPermission>(_onRequestSpecificPermission);
    on<CheckPermissions>(_onCheckPermissions);
    on<StartBlocking>(_onStartBlocking);
    on<StopBlocking>(_onStopBlocking);
    on<FilterApps>(_onFilterApps);
    on<RequestAllPermissions>(_onRequestAllPermissions);
    on<OpenAppSettings>(_onOpenAppSettings);
  }

  Future<void> _onLoadInstalledApps(
    LoadInstalledApps event,
    Emitter<BlockSetupState> emit,
  ) async {
    try {
      emit(BlockSetupLoading());
      
      // Load all apps but paginate the display
      final allInstalledApps = await _getInstalledApps();
      final blockedApps = await _repository.getBlockedApps();
      
      // Use the new permission status service for real-time status
      final permissionStatuses = await _permissionStatusService.checkAllPermissionStatus();
      
      final hasUsageStats = permissionStatuses[PermissionType.usageStats]?.isGranted ?? false;
      final hasAccessibility = permissionStatuses[PermissionType.accessibility]?.isGranted ?? false;
      final hasDeviceAdmin = permissionStatuses[PermissionType.deviceAdmin]?.isGranted ?? false;
      final hasOverlay = permissionStatuses[PermissionType.overlay]?.isGranted ?? false;
      final isBlocking = await _repository.isBlocking();
      
      // Create blocked apps map for O(1) lookup
      final blockedAppsMap = <String, bool>{};
      for (final blockedApp in blockedApps) {
        blockedAppsMap[blockedApp.packageName] = true;
      }
      
      // Merge installed apps with blocked status using efficient lookup
      final mergedApps = allInstalledApps.map((app) {
        final isBlocked = blockedAppsMap.containsKey(app.packageName);
        return app.copyWith(isBlocked: isBlocked);
      }).toList();
      
      // Sort apps to prioritize social media apps
      mergedApps.sort((a, b) {
        final aSocial = _isSocialMediaApp(a.packageName);
        final bSocial = _isSocialMediaApp(b.packageName);
        
        if (aSocial && !bSocial) return -1;
        if (!aSocial && bSocial) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      
      // Initialize pagination
      const appsPerPage = 25;
      final paginatedApps = _getPaginatedApps(mergedApps, 1, appsPerPage);
      final hasMoreApps = mergedApps.length > appsPerPage;
      
      emit(BlockSetupLoaded(
        installedApps: mergedApps,
        blockedApps: blockedApps,
        filteredApps: paginatedApps,
        hasUsageStatsPermission: hasUsageStats,
        hasAccessibilityPermission: hasAccessibility,
        hasDeviceAdminPermission: hasDeviceAdmin,
        hasOverlayPermission: hasOverlay,
        isBlocking: isBlocking,
        hasMoreApps: hasMoreApps,
        currentPage: 1,
        appsPerPage: appsPerPage,
      ));
    } catch (e) {
      emit(BlockSetupError(e.toString()));
    }
  }
  
  Future<void> _onLoadMoreApps(
    LoadMoreApps event,
    Emitter<BlockSetupState> emit,
  ) async {
    if (state is! BlockSetupLoaded) return;
    
    final currentState = state as BlockSetupLoaded;
    
    // Don't load if already loading or no more apps
    if (currentState.isLoadingMore || !currentState.hasMoreApps) return;
    
    try {
      // Show loading state
      emit(currentState.copyWith(isLoadingMore: true));
      
      // Calculate next page
      final nextPage = currentState.currentPage + 1;
      final startIndex = (nextPage - 1) * currentState.appsPerPage;
      final endIndex = startIndex + currentState.appsPerPage;
      
      // Filter apps based on current search query
      final appsToFilter = currentState.searchQuery.isEmpty 
          ? currentState.installedApps
          : _filterApps(currentState.installedApps, currentState.searchQuery);
      
      // Get new batch of apps
      final newApps = appsToFilter.skip(startIndex).take(currentState.appsPerPage).toList();
      
      // Combine with existing filtered apps
      final updatedFilteredApps = [...currentState.filteredApps, ...newApps];
      
      // Check if there are more apps to load
      final hasMoreApps = endIndex < appsToFilter.length;
      
      emit(currentState.copyWith(
        filteredApps: updatedFilteredApps,
        isLoadingMore: false,
        hasMoreApps: hasMoreApps,
        currentPage: nextPage,
      ));
    } catch (e) {
      emit(currentState.copyWith(
        isLoadingMore: false,
      ));
    }
  }
  
  List<BlockedApp> _getPaginatedApps(List<BlockedApp> apps, int page, int appsPerPage) {
    final startIndex = (page - 1) * appsPerPage;
    final endIndex = startIndex + appsPerPage;
    
    if (startIndex >= apps.length) return [];
    
    return apps.sublist(startIndex, endIndex.clamp(0, apps.length));
  }
  
  bool _isSocialMediaApp(String packageName) {
    final socialMediaApps = {
      'com.facebook.katana',
      'com.instagram.android',
      'com.twitter.android',
      'com.snapchat.android',
      'com.linkedin.android',
      'com.pinterest',
      'com.tiktok.musically',
      'com.reddit.frontpage',
      'com.tumblr',
      'com.discord',
      'com.whatsapp',
      'com.telegram.messenger',
      'com.zhiliaoapp.musically',
    };
    
    return socialMediaApps.contains(packageName);
  }

  Future<void> _onLoadBlockedApps(
    LoadBlockedApps event,
    Emitter<BlockSetupState> emit,
  ) async {
    try {
      final blockedApps = await _repository.getBlockedApps();
      
      if (state is BlockSetupLoaded) {
        final currentState = state as BlockSetupLoaded;
        emit(currentState.copyWith(blockedApps: blockedApps));
      }
    } catch (e) {
      emit(BlockSetupError(e.toString()));
    }
  }

  Future<void> _onToggleAppBlocking(
    ToggleAppBlocking event,
    Emitter<BlockSetupState> emit,
  ) async {
    try {
      await _toggleAppBlocking(event.app, event.isBlocked);
      
      if (state is BlockSetupLoaded) {
        final currentState = state as BlockSetupLoaded;
        
        // Update the app in the installed apps list
        final updatedInstalledApps = currentState.installedApps.map((app) {
          if (app.packageName == event.app.packageName) {
            return app.copyWith(isBlocked: event.isBlocked);
          }
          return app;
        }).toList();
        
        // Update blocked apps list
        final updatedBlockedApps = await _repository.getBlockedApps();
        
        // Update filtered apps
        final updatedFilteredApps = _filterApps(updatedInstalledApps, currentState.searchQuery);
        
        emit(currentState.copyWith(
          installedApps: updatedInstalledApps,
          blockedApps: updatedBlockedApps,
          filteredApps: updatedFilteredApps,
        ));
      }
    } catch (e) {
      emit(BlockSetupError(e.toString()));
    }
  }

  Future<void> _onRequestPermissions(
    RequestPermissions event,
    Emitter<BlockSetupState> emit,
  ) async {
    // Start sequential permission flow
    add(const RequestNextPermission());
  }

  Future<void> _onRequestNextPermission(
    RequestNextPermission event,
    Emitter<BlockSetupState> emit,
  ) async {
    if (state is! BlockSetupLoaded) return;
    
    final currentState = state as BlockSetupLoaded;
    
    // Define permission order and check what's missing
    final permissions = [
      {'type': 'usage_stats', 'name': 'Usage Stats', 'granted': currentState.hasUsageStatsPermission},
      {'type': 'accessibility', 'name': 'Accessibility Service', 'granted': currentState.hasAccessibilityPermission},
      {'type': 'device_admin', 'name': 'Device Administrator', 'granted': currentState.hasDeviceAdminPermission},
      {'type': 'overlay', 'name': 'Display Over Other Apps', 'granted': currentState.hasOverlayPermission},
    ];
    
    // Find the first permission that's not granted
    final missingPermission = permissions.firstWhere(
      (permission) => !(permission['granted'] as bool),
      orElse: () => {},
    );
    
    if (missingPermission.isEmpty) {
      // All permissions are granted
      emit(PermissionSequentialCompleted());
      add(CheckPermissions());
      return;
    }
    
    final currentIndex = permissions.indexOf(missingPermission);
    emit(PermissionSequentialRequesting(
      currentPermission: missingPermission['name'] as String,
      currentStep: currentIndex + 1,
      totalSteps: permissions.length,
    ));
    
    // Request the specific permission
    add(RequestSpecificPermission(missingPermission['type'] as String));
  }

  Future<void> _onRequestSpecificPermission(
    RequestSpecificPermission event,
    Emitter<BlockSetupState> emit,
  ) async {
    try {
      PermissionType? permissionType;
      
      switch (event.permissionType) {
        case 'usage_stats':
          permissionType = PermissionType.usageStats;
          break;
        case 'accessibility':
          permissionType = PermissionType.accessibility;
          break;
        case 'device_admin':
          permissionType = PermissionType.deviceAdmin;
          break;
        case 'overlay':
          permissionType = PermissionType.overlay;
          break;
      }
      
      if (permissionType != null) {
        // Use the new permission status service
        await _permissionStatusService.requestPermission(permissionType);
      }
      
      // Wait a moment for the user to potentially grant the permission
      await Future.delayed(const Duration(seconds: 2));
      
      // Check permissions and continue with the next one
      add(CheckPermissions());
      
      // After a short delay, request the next permission if needed
      await Future.delayed(const Duration(milliseconds: 500));
      add(const RequestNextPermission());
      
    } catch (e) {
      emit(PermissionDenied('Failed to request ${event.permissionType}: $e'));
    }
  }

  Future<void> _onCheckPermissions(
    CheckPermissions event,
    Emitter<BlockSetupState> emit,
  ) async {
    try {
      if (state is BlockSetupLoaded) {
        final currentState = state as BlockSetupLoaded;
        
        // Use the new permission status service for real-time updates
        final permissionStatuses = await _permissionStatusService.checkAllPermissionStatus();
        
        final hasUsageStats = permissionStatuses[PermissionType.usageStats]?.isGranted ?? false;
        final hasAccessibility = permissionStatuses[PermissionType.accessibility]?.isGranted ?? false;
        final hasDeviceAdmin = permissionStatuses[PermissionType.deviceAdmin]?.isGranted ?? false;
        final hasOverlay = permissionStatuses[PermissionType.overlay]?.isGranted ?? false;
        
        emit(currentState.copyWith(
          hasUsageStatsPermission: hasUsageStats,
          hasAccessibilityPermission: hasAccessibility,
          hasDeviceAdminPermission: hasDeviceAdmin,
          hasOverlayPermission: hasOverlay,
        ));
      }
    } catch (e) {
      emit(BlockSetupError(e.toString()));
    }
  }

  Future<void> _onStartBlocking(
    StartBlocking event,
    Emitter<BlockSetupState> emit,
  ) async {
    try {
      if (state is BlockSetupLoaded) {
        final currentState = state as BlockSetupLoaded;
        final blockedPackageNames = currentState.blockedApps.map((app) => app.packageName).toList();
        
        await _repository.startBlocking(blockedPackageNames);
        
        emit(currentState.copyWith(isBlocking: true));
      }
    } catch (e) {
      emit(BlockSetupError(e.toString()));
    }
  }

  Future<void> _onStopBlocking(
    StopBlocking event,
    Emitter<BlockSetupState> emit,
  ) async {
    try {
      if (state is BlockSetupLoaded) {
        final currentState = state as BlockSetupLoaded;
        
        await _repository.stopBlocking();
        
        emit(currentState.copyWith(isBlocking: false));
      }
    } catch (e) {
      emit(BlockSetupError(e.toString()));
    }
  }

  Future<void> _onFilterApps(
    FilterApps event,
    Emitter<BlockSetupState> emit,
  ) async {
    if (state is BlockSetupLoaded) {
      final currentState = state as BlockSetupLoaded;
      final allFilteredApps = _filterApps(currentState.installedApps, event.query);
      
      // Reset to first page when searching
      final paginatedApps = _getPaginatedApps(allFilteredApps, 1, currentState.appsPerPage);
      final hasMoreApps = allFilteredApps.length > currentState.appsPerPage;
      
      emit(currentState.copyWith(
        filteredApps: paginatedApps,
        searchQuery: event.query,
        currentPage: 1,
        hasMoreApps: hasMoreApps,
        isLoadingMore: false,
      ));
    }
  }

  List<BlockedApp> _filterApps(List<BlockedApp> apps, String query) {
    if (query.isEmpty) return apps;
    
    return apps.where((app) {
      return app.name.toLowerCase().contains(query.toLowerCase()) ||
             app.packageName.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }
  
  Future<void> _onRequestAllPermissions(
    RequestAllPermissions event,
    Emitter<BlockSetupState> emit,
  ) async {
    try {
      emit(PermissionRequesting());
      
      // Use the new permission service for comprehensive permission handling
      final result = await _permissionService.requestAllPermissions();
      
      // Check if critical permissions were denied
      if (result.criticalDenied) {
        emit(PermissionDenied('Critical permissions were denied. The app requires usage stats and accessibility permissions to function properly.'));
        return;
      }
      
      // Wait a moment then check permissions
      await Future.delayed(const Duration(seconds: 1));
      add(CheckPermissions());
    } catch (e) {
      emit(PermissionDenied('Failed to request all permissions: $e'));
    }
  }
  
  Future<void> _onOpenAppSettings(
    OpenAppSettings event,
    Emitter<BlockSetupState> emit,
  ) async {
    try {
      // Open general app settings - users can navigate to specific permissions from there
      await _permissionService.openPermissionSettings(PermissionType.usageStats);
      
      // Wait a moment then check permissions
      await Future.delayed(const Duration(seconds: 1));
      add(CheckPermissions());
    } catch (e) {
      emit(BlockSetupError('Failed to open app settings: $e'));
    }
  }
}