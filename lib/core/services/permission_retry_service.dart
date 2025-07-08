import 'dart:async';
import 'dart:math';
import 'package:injectable/injectable.dart';
import 'permission_service.dart';
import 'permission_error_handler.dart';

/// Smart retry service for failed permission requests
@injectable
class PermissionRetryService {
  final PermissionService _permissionService;
  final PermissionErrorHandler _errorHandler;
  
  final Map<PermissionType, RetryContext> _retryContexts = {};
  final Map<PermissionType, Timer?> _retryTimers = {};

  PermissionRetryService(this._permissionService, this._errorHandler);

  /// Request a permission with intelligent retry logic
  Future<PermissionResult> requestPermissionWithRetry(
    PermissionType permissionType, {
    RetryStrategy strategy = RetryStrategy.adaptive,
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
    Function(int attempt, Duration nextDelay)? onRetryAttempt,
  }) async {
    final context = _getOrCreateRetryContext(permissionType, strategy, maxRetries, initialDelay);
    
    try {
      final result = await _permissionService.requestPermission(permissionType);
      
      if (result.isGranted) {
        // Success - reset retry context
        _clearRetryContext(permissionType);
        return result;
      } else if (!result.canRetry || context.shouldGiveUp()) {
        // Permanent failure or max retries reached
        _clearRetryContext(permissionType);
        return result;
      } else {
        // Schedule retry
        return await _scheduleRetry(permissionType, context, onRetryAttempt);
      }
    } catch (e) {
      // Handle unexpected errors
      final error = _errorHandler.handleGeneralException(
        Exception(e.toString()), 
        permissionType
      );
      
      if (error.canRetry && !context.shouldGiveUp()) {
        return await _scheduleRetry(permissionType, context, onRetryAttempt);
      } else {
        _clearRetryContext(permissionType);
        return PermissionResult.fromPermissionError(error);
      }
    }
  }

  /// Cancel all pending retries for a specific permission
  void cancelRetries(PermissionType permissionType) {
    _retryTimers[permissionType]?.cancel();
    _retryTimers.remove(permissionType);
    _retryContexts.remove(permissionType);
  }

  /// Cancel all pending retries
  void cancelAllRetries() {
    for (final timer in _retryTimers.values) {
      timer?.cancel();
    }
    _retryTimers.clear();
    _retryContexts.clear();
  }

  /// Get retry status for a permission
  RetryStatus getRetryStatus(PermissionType permissionType) {
    final context = _retryContexts[permissionType];
    final hasTimer = _retryTimers[permissionType] != null;
    
    if (context == null) {
      return RetryStatus.notActive;
    } else if (hasTimer) {
      return RetryStatus.scheduled;
    } else if (context.shouldGiveUp()) {
      return RetryStatus.exhausted;
    } else {
      return RetryStatus.ready;
    }
  }

  /// Get time until next retry attempt
  Duration? getTimeUntilNextRetry(PermissionType permissionType) {
    final context = _retryContexts[permissionType];
    return context?.timeUntilNextRetry;
  }

  RetryContext _getOrCreateRetryContext(
    PermissionType permissionType,
    RetryStrategy strategy,
    int maxRetries,
    Duration initialDelay,
  ) {
    return _retryContexts.putIfAbsent(
      permissionType,
      () => RetryContext(
        permissionType: permissionType,
        strategy: strategy,
        maxRetries: maxRetries,
        initialDelay: initialDelay,
      ),
    );
  }

  Future<PermissionResult> _scheduleRetry(
    PermissionType permissionType,
    RetryContext context,
    Function(int attempt, Duration nextDelay)? onRetryAttempt,
  ) async {
    final delay = context.getNextDelay();
    context.incrementAttempt();
    
    onRetryAttempt?.call(context.attemptCount, delay);
    
    final completer = Completer<PermissionResult>();
    
    _retryTimers[permissionType] = Timer(delay, () async {
      _retryTimers.remove(permissionType);
      
      try {
        final result = await requestPermissionWithRetry(
          permissionType,
          strategy: context.strategy,
          maxRetries: context.maxRetries,
          initialDelay: context.initialDelay,
          onRetryAttempt: onRetryAttempt,
        );
        completer.complete(result);
      } catch (e) {
        final error = _errorHandler.handleGeneralException(
          Exception(e.toString()),
          permissionType,
        );
        completer.complete(PermissionResult.fromPermissionError(error));
      }
    });
    
    return completer.future;
  }

  void _clearRetryContext(PermissionType permissionType) {
    _retryTimers[permissionType]?.cancel();
    _retryTimers.remove(permissionType);
    _retryContexts.remove(permissionType);
  }

  void dispose() {
    cancelAllRetries();
  }
}

/// Retry strategies for different scenarios
enum RetryStrategy {
  /// No retries
  none,
  /// Fixed delay between retries
  fixed,
  /// Exponential backoff
  exponential,
  /// Adaptive strategy based on permission type and error
  adaptive,
  /// Linear increase in delay
  linear,
}

/// Status of retry operations
enum RetryStatus {
  /// No retry is active
  notActive,
  /// Retry is scheduled
  scheduled,
  /// Ready for retry
  ready,
  /// Max retries exhausted
  exhausted,
}

/// Context for tracking retry attempts
class RetryContext {
  final PermissionType permissionType;
  final RetryStrategy strategy;
  final int maxRetries;
  final Duration initialDelay;
  
  int attemptCount = 0;
  DateTime? lastAttempt;
  DateTime? nextRetryTime;

  RetryContext({
    required this.permissionType,
    required this.strategy,
    required this.maxRetries,
    required this.initialDelay,
  });

  bool shouldGiveUp() {
    return attemptCount >= maxRetries;
  }

  Duration getNextDelay() {
    switch (strategy) {
      case RetryStrategy.none:
        return Duration.zero;
      case RetryStrategy.fixed:
        return initialDelay;
      case RetryStrategy.exponential:
        return Duration(
          milliseconds: (initialDelay.inMilliseconds * pow(2, attemptCount)).round(),
        );
      case RetryStrategy.linear:
        return Duration(
          milliseconds: initialDelay.inMilliseconds * (attemptCount + 1),
        );
      case RetryStrategy.adaptive:
        return _getAdaptiveDelay();
    }
  }

  Duration _getAdaptiveDelay() {
    // Adaptive strategy based on permission type and attempt count
    switch (permissionType) {
      case PermissionType.notification:
      case PermissionType.location:
        // Standard permissions - shorter delays
        return Duration(seconds: min(2 + attemptCount, 10));
      
      case PermissionType.usageStats:
      case PermissionType.accessibility:
      case PermissionType.deviceAdmin:
        // System permissions - longer delays as user might need more time
        return Duration(seconds: min(5 + (attemptCount * 2), 30));
      
      case PermissionType.overlay:
      case PermissionType.vpn:
        // Special permissions - moderate delays
        return Duration(seconds: min(3 + attemptCount, 15));
    }
  }

  void incrementAttempt() {
    attemptCount++;
    lastAttempt = DateTime.now();
    nextRetryTime = lastAttempt!.add(getNextDelay());
  }

  Duration? get timeUntilNextRetry {
    if (nextRetryTime == null) return null;
    
    final now = DateTime.now();
    if (now.isAfter(nextRetryTime!)) return Duration.zero;
    
    return nextRetryTime!.difference(now);
  }
}

/// Enhanced permission service with built-in retry logic
@injectable
class EnhancedPermissionService {
  final PermissionRetryService _retryService;
  final PermissionService _permissionService;

  EnhancedPermissionService(this._retryService, this._permissionService);

  /// Request permission with smart retry logic
  Future<PermissionResult> requestPermission(
    PermissionType permissionType, {
    bool enableRetry = true,
    RetryStrategy strategy = RetryStrategy.adaptive,
    int maxRetries = 3,
    Function(int attempt, Duration nextDelay)? onRetryAttempt,
  }) async {
    if (!enableRetry) {
      return await _permissionService.requestPermission(permissionType);
    }

    return await _retryService.requestPermissionWithRetry(
      permissionType,
      strategy: strategy,
      maxRetries: maxRetries,
      onRetryAttempt: onRetryAttempt,
    );
  }

  /// Request all permissions with retry logic
  Future<PermissionRequestResult> requestAllPermissions({
    bool enableRetry = true,
    RetryStrategy strategy = RetryStrategy.adaptive,
    int maxRetries = 2, // Lower for batch operations
    Function(PermissionType permission, int attempt, Duration nextDelay)? onRetryAttempt,
  }) async {
    final results = <PermissionType, PermissionResult>{};
    
    // Define permission order by priority
    final permissionOrder = [
      PermissionType.usageStats,
      PermissionType.accessibility,
      PermissionType.deviceAdmin,
      PermissionType.overlay,
      PermissionType.notification,
      PermissionType.location,
      PermissionType.vpn,
    ];

    for (final permissionType in permissionOrder) {
      final result = await requestPermission(
        permissionType,
        enableRetry: enableRetry,
        strategy: strategy,
        maxRetries: maxRetries,
        onRetryAttempt: (attempt, delay) => 
          onRetryAttempt?.call(permissionType, attempt, delay),
      );
      
      results[permissionType] = result;
      
      // Add small delay between permission requests to improve UX
      if (permissionType != permissionOrder.last) {
        await Future.delayed(Duration(milliseconds: 500));
      }
    }

    return PermissionRequestResult(
      results: results,
      allGranted: results.values.every((result) => result.isGranted),
      criticalDenied: _hasCriticalDenied(results),
    );
  }

  /// Cancel retries for a specific permission
  void cancelRetries(PermissionType permissionType) {
    _retryService.cancelRetries(permissionType);
  }

  /// Cancel all pending retries
  void cancelAllRetries() {
    _retryService.cancelAllRetries();
  }

  /// Get retry status for a permission
  RetryStatus getRetryStatus(PermissionType permissionType) {
    return _retryService.getRetryStatus(permissionType);
  }

  /// Check if any retries are currently active
  bool get hasActiveRetries {
    return PermissionType.values.any((type) => 
      getRetryStatus(type) == RetryStatus.scheduled
    );
  }

  /// Get time until next retry for a permission
  Duration? getTimeUntilNextRetry(PermissionType permissionType) {
    return _retryService.getTimeUntilNextRetry(permissionType);
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

  void dispose() {
    _retryService.dispose();
  }
}

/// Helper class for retry feedback utilities
class RetryFeedbackHelper {
  static String getPermissionName(PermissionType permissionType) {
    switch (permissionType) {
      case PermissionType.notification:
        return 'Notification';
      case PermissionType.location:
        return 'Location';
      case PermissionType.usageStats:
        return 'Usage Statistics';
      case PermissionType.accessibility:
        return 'Accessibility';
      case PermissionType.deviceAdmin:
        return 'Device Admin';
      case PermissionType.overlay:
        return 'Overlay';
      case PermissionType.vpn:
        return 'VPN';
    }
  }
  
  static String getRetryMessage(PermissionType permissionType, int attempt, Duration nextDelay) {
    final permissionName = getPermissionName(permissionType);
    final delaySeconds = nextDelay.inSeconds;
    return 'Retrying $permissionName permission in ${delaySeconds}s (attempt $attempt)';
  }
}