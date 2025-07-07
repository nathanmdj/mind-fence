import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'block_setup_event.dart';
import 'block_setup_state.dart';
import '../../domain/usecases/get_installed_apps.dart';
import '../../domain/usecases/toggle_app_blocking.dart' as usecases;
import '../../domain/usecases/request_permissions.dart' as usecases;
import '../../domain/repositories/blocking_repository.dart';
import '../../../../shared/domain/entities/blocked_app.dart';

@injectable
class BlockSetupBloc extends Bloc<BlockSetupEvent, BlockSetupState> {
  final GetInstalledApps _getInstalledApps;
  final usecases.ToggleAppBlocking _toggleAppBlocking;
  final usecases.RequestPermissions _requestPermissions;
  final BlockingRepository _repository;

  BlockSetupBloc(
    this._getInstalledApps,
    this._toggleAppBlocking,
    this._requestPermissions,
    this._repository,
  ) : super(BlockSetupInitial()) {
    on<LoadInstalledApps>(_onLoadInstalledApps);
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
      
      final installedApps = await _getInstalledApps();
      final blockedApps = await _repository.getBlockedApps();
      final hasUsageStats = await _requestPermissions.hasUsageStatsPermission();
      final hasAccessibility = await _requestPermissions.hasAccessibilityPermission();
      final hasDeviceAdmin = await _requestPermissions.hasDeviceAdminPermission();
      final hasOverlay = await _requestPermissions.hasOverlayPermission();
      final isBlocking = await _repository.isBlocking();
      
      // Merge installed apps with blocked status
      final mergedApps = installedApps.map((app) {
        final isBlocked = blockedApps.any((blocked) => blocked.packageName == app.packageName);
        return app.copyWith(isBlocked: isBlocked);
      }).toList();
      
      emit(BlockSetupLoaded(
        installedApps: mergedApps,
        blockedApps: blockedApps,
        filteredApps: mergedApps,
        hasUsageStatsPermission: hasUsageStats,
        hasAccessibilityPermission: hasAccessibility,
        hasDeviceAdminPermission: hasDeviceAdmin,
        hasOverlayPermission: hasOverlay,
        isBlocking: isBlocking,
      ));
    } catch (e) {
      emit(BlockSetupError(e.toString()));
    }
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
      switch (event.permissionType) {
        case 'usage_stats':
          await _requestPermissions.requestUsageStatsPermission();
          break;
        case 'accessibility':
          await _requestPermissions.requestAccessibilityPermission();
          break;
        case 'device_admin':
          await _requestPermissions.requestDeviceAdminPermission();
          break;
        case 'overlay':
          await _requestPermissions.requestOverlayPermission();
          break;
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
        final hasUsageStats = await _requestPermissions.hasUsageStatsPermission();
        final hasAccessibility = await _requestPermissions.hasAccessibilityPermission();
        final hasDeviceAdmin = await _requestPermissions.hasDeviceAdminPermission();
        final hasOverlay = await _requestPermissions.hasOverlayPermission();
        
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
      final filteredApps = _filterApps(currentState.installedApps, event.query);
      
      emit(currentState.copyWith(
        filteredApps: filteredApps,
        searchQuery: event.query,
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
      await _requestPermissions.requestAllPermissions();
      
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
      await _requestPermissions.openAppSettings();
      
      // Wait a moment then check permissions
      await Future.delayed(const Duration(seconds: 1));
      add(CheckPermissions());
    } catch (e) {
      emit(BlockSetupError('Failed to open app settings: $e'));
    }
  }
}