import '../entities/emergency_override.dart';

abstract class EmergencyOverrideRepository {
  Future<EmergencyOverride> requestOverride({
    required String reason,
    required Duration delayDuration,
    required Duration overrideDuration,
  });
  Future<void> activateOverride(String overrideId);
  Future<void> cancelOverride(String overrideId);
  Future<EmergencyOverride?> getCurrentOverride();
  Future<List<EmergencyOverride>> getOverrideHistory();
  Future<bool> hasActiveOverride();
  Future<void> expireOverride(String overrideId);
  Future<void> cleanupExpiredOverrides();
}