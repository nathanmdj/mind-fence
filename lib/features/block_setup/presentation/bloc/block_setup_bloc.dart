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
    on<CheckPermissions>(_onCheckPermissions);
    on<StartBlocking>(_onStartBlocking);
    on<StopBlocking>(_onStopBlocking);
    on<FilterApps>(_onFilterApps);
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
    try {
      emit(PermissionRequesting());
      
      await _requestPermissions.requestUsageStatsPermission();
      await _requestPermissions.requestAccessibilityPermission();
      await _requestPermissions.requestOverlayPermission();
      
      emit(PermissionGranted());
      
      // Reload to check permissions
      add(CheckPermissions());
    } catch (e) {
      emit(PermissionDenied(e.toString()));
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
        final hasOverlay = await _requestPermissions.hasOverlayPermission();
        
        emit(currentState.copyWith(
          hasUsageStatsPermission: hasUsageStats,
          hasAccessibilityPermission: hasAccessibility,
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
}