import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';

/// Service that manages app lifecycle events and notifies listeners
@injectable
class AppLifecycleService with WidgetsBindingObserver {
  final List<VoidCallback> _resumeCallbacks = [];
  final List<VoidCallback> _pauseCallbacks = [];
  
  bool _isInitialized = false;
  
  /// Initialize the service - should be called from main.dart
  void initialize() {
    if (!_isInitialized) {
      WidgetsBinding.instance.addObserver(this);
      _isInitialized = true;
    }
  }
  
  /// Dispose of the service
  void dispose() {
    if (_isInitialized) {
      WidgetsBinding.instance.removeObserver(this);
      _isInitialized = false;
    }
    _resumeCallbacks.clear();
    _pauseCallbacks.clear();
  }
  
  /// Register a callback to be called when the app resumes
  void addResumeCallback(VoidCallback callback) {
    _resumeCallbacks.add(callback);
  }
  
  /// Register a callback to be called when the app is paused
  void addPauseCallback(VoidCallback callback) {
    _pauseCallbacks.add(callback);
  }
  
  /// Remove a resume callback
  void removeResumeCallback(VoidCallback callback) {
    _resumeCallbacks.remove(callback);
  }
  
  /// Remove a pause callback
  void removePauseCallback(VoidCallback callback) {
    _pauseCallbacks.remove(callback);
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        // App has resumed from background
        _notifyResumeCallbacks();
        break;
      case AppLifecycleState.paused:
        // App has been paused (moved to background)
        _notifyPauseCallbacks();
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // Handle other states if needed
        break;
    }
  }
  
  void _notifyResumeCallbacks() {
    for (final callback in _resumeCallbacks) {
      try {
        callback();
      } catch (e) {
        // Log error but continue with other callbacks
        debugPrint('Error in resume callback: $e');
      }
    }
  }
  
  void _notifyPauseCallbacks() {
    for (final callback in _pauseCallbacks) {
      try {
        callback();
      } catch (e) {
        // Log error but continue with other callbacks
        debugPrint('Error in pause callback: $e');
      }
    }
  }
}

/// Mixin for widgets that need to respond to app lifecycle changes
mixin AppLifecycleAware {
  late AppLifecycleService _lifecycleService;
  
  /// Initialize lifecycle awareness - call this in initState
  void initializeLifecycleAware(AppLifecycleService lifecycleService) {
    _lifecycleService = lifecycleService;
    _lifecycleService.addResumeCallback(onAppResumed);
    _lifecycleService.addPauseCallback(onAppPaused);
  }
  
  /// Clean up lifecycle awareness - call this in dispose
  void disposeLifecycleAware() {
    _lifecycleService.removeResumeCallback(onAppResumed);
    _lifecycleService.removePauseCallback(onAppPaused);
  }
  
  /// Called when the app resumes from background
  void onAppResumed() {}
  
  /// Called when the app is paused (moved to background)
  void onAppPaused() {}
}