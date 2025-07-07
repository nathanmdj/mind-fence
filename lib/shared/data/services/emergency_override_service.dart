import 'dart:async';
import 'package:injectable/injectable.dart';
import '../../domain/repositories/emergency_override_repository.dart';
import '../../domain/entities/emergency_override.dart';
import '../datasources/blocked_apps_datasource.dart';

@injectable
class EmergencyOverrideService {
  final EmergencyOverrideRepository _overrideRepository;
  final BlockedAppsDataSource _blockedAppsDataSource;
  Timer? _overrideTimer;
  EmergencyOverride? _currentOverride;

  EmergencyOverrideService(this._overrideRepository, this._blockedAppsDataSource);

  void startMonitoring() {
    // Check every 30 seconds for override status changes
    _overrideTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkOverrideStatus();
    });
    
    // Also check immediately
    _checkOverrideStatus();
  }

  void stopMonitoring() {
    _overrideTimer?.cancel();
    _overrideTimer = null;
  }

  Future<void> _checkOverrideStatus() async {
    try {
      final currentOverride = await _overrideRepository.getCurrentOverride();
      
      // If no override exists, ensure blocking is active
      if (currentOverride == null) {
        if (_currentOverride != null) {
          // Previous override has ended, resume normal blocking
          await _resumeNormalBlocking();
          _currentOverride = null;
        }
        return;
      }

      // Check if override should expire
      if (currentOverride.shouldExpire) {
        await _overrideRepository.expireOverride(currentOverride.id);
        await _resumeNormalBlocking();
        _currentOverride = null;
        return;
      }

      // If override is active and was not previously active
      if (currentOverride.isActive && _currentOverride?.isActive != true) {
        await _suspendBlocking();
        _currentOverride = currentOverride;
      }
      
      // Update current override
      _currentOverride = currentOverride;
      
    } catch (e) {
      print('Error checking override status: $e');
    }
  }

  Future<EmergencyOverride> requestEmergencyOverride({
    required String reason,
    Duration delayDuration = const Duration(minutes: 10),
    Duration overrideDuration = const Duration(minutes: 30),
  }) async {
    return await _overrideRepository.requestOverride(
      reason: reason,
      delayDuration: delayDuration,
      overrideDuration: overrideDuration,
    );
  }

  Future<void> activateOverride(String overrideId) async {
    await _overrideRepository.activateOverride(overrideId);
    await _suspendBlocking();
  }

  Future<void> cancelOverride(String overrideId) async {
    await _overrideRepository.cancelOverride(overrideId);
    await _resumeNormalBlocking();
    _currentOverride = null;
  }

  Future<EmergencyOverride?> getCurrentOverride() async {
    return await _overrideRepository.getCurrentOverride();
  }

  Future<bool> hasActiveOverride() async {
    return await _overrideRepository.hasActiveOverride();
  }

  Future<void> _suspendBlocking() async {
    try {
      // Stop app blocking during override
      await _blockedAppsDataSource.stopBlocking();
      print('Blocking suspended due to emergency override');
    } catch (e) {
      print('Error suspending blocking: $e');
    }
  }

  Future<void> _resumeNormalBlocking() async {
    try {
      // This would need to check current schedules and blocked apps
      // For now, we'll just ensure the blocking service is aware
      final blockedApps = await _blockedAppsDataSource.getBlockedApps();
      final activeApps = blockedApps
          .where((app) => app.isBlocked)
          .map((app) => app.packageName)
          .toList();
      
      if (activeApps.isNotEmpty) {
        await _blockedAppsDataSource.startBlocking(activeApps);
      }
      
      print('Normal blocking resumed');
    } catch (e) {
      print('Error resuming blocking: $e');
    }
  }

  void dispose() {
    stopMonitoring();
  }
}