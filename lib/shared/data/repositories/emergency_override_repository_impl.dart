import 'package:injectable/injectable.dart';
import '../datasources/emergency_override_datasource.dart';
import '../models/emergency_override_model.dart';
import '../../domain/entities/emergency_override.dart';
import '../../domain/repositories/emergency_override_repository.dart';

@Injectable(as: EmergencyOverrideRepository)
class EmergencyOverrideRepositoryImpl implements EmergencyOverrideRepository {
  final EmergencyOverrideDataSource _dataSource;

  EmergencyOverrideRepositoryImpl(this._dataSource);

  @override
  Future<EmergencyOverride> requestOverride({
    required String reason,
    required Duration delayDuration,
    required Duration overrideDuration,
  }) async {
    // Cancel any existing pending override
    final existing = await getCurrentOverride();
    if (existing != null && !existing.isActive && !existing.hasExpired) {
      await cancelOverride(existing.id);
    }

    final override = EmergencyOverride(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      requestedAt: DateTime.now(),
      delayDuration: delayDuration,
      overrideDuration: overrideDuration,
      reason: reason,
      isActive: false,
      hasExpired: false,
    );

    final model = EmergencyOverrideModel.fromDomain(override);
    await _dataSource.createOverride(model);
    return override;
  }

  @override
  Future<void> activateOverride(String overrideId) async {
    final current = await getCurrentOverride();
    if (current == null || current.id != overrideId) {
      throw Exception('Override not found or not current');
    }

    if (!current.canActivate) {
      throw Exception('Override cannot be activated yet');
    }

    final updatedOverride = current.copyWith(
      isActive: true,
      activatedAt: DateTime.now(),
    );

    final model = EmergencyOverrideModel.fromDomain(updatedOverride);
    await _dataSource.updateOverride(model);
  }

  @override
  Future<void> cancelOverride(String overrideId) async {
    final current = await getCurrentOverride();
    if (current == null || current.id != overrideId) {
      throw Exception('Override not found or not current');
    }

    final updatedOverride = current.copyWith(
      hasExpired: true,
    );

    final model = EmergencyOverrideModel.fromDomain(updatedOverride);
    await _dataSource.updateOverride(model);
  }

  @override
  Future<EmergencyOverride?> getCurrentOverride() async {
    final model = await _dataSource.getCurrentOverride();
    return model?.toDomain();
  }

  @override
  Future<List<EmergencyOverride>> getOverrideHistory() async {
    final models = await _dataSource.getOverrideHistory();
    return models.map((model) => model.toDomain()).toList();
  }

  @override
  Future<bool> hasActiveOverride() async {
    final current = await getCurrentOverride();
    return current?.isActive == true && !current!.shouldExpire;
  }

  @override
  Future<void> expireOverride(String overrideId) async {
    final current = await getCurrentOverride();
    if (current == null || current.id != overrideId) {
      return; // Already expired or not found
    }

    final updatedOverride = current.copyWith(
      isActive: false,
      hasExpired: true,
    );

    final model = EmergencyOverrideModel.fromDomain(updatedOverride);
    await _dataSource.updateOverride(model);
  }

  @override
  Future<void> cleanupExpiredOverrides() async {
    // Delete overrides older than 30 days
    final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
    final history = await getOverrideHistory();
    
    for (final override in history) {
      if (override.requestedAt.isBefore(cutoffDate) && override.hasExpired) {
        await _dataSource.deleteOverride(override.id);
      }
    }
  }
}