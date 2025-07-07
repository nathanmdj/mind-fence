import 'package:injectable/injectable.dart';
import '../entities/emergency_override.dart';
import '../repositories/emergency_override_repository.dart';

@injectable
class RequestEmergencyOverride {
  final EmergencyOverrideRepository _repository;

  RequestEmergencyOverride(this._repository);

  Future<EmergencyOverride> call({
    required String reason,
    Duration delayDuration = const Duration(minutes: 10),
    Duration overrideDuration = const Duration(minutes: 30),
  }) async {
    if (reason.trim().isEmpty) {
      throw Exception('Reason cannot be empty');
    }

    if (delayDuration.inMinutes < 1) {
      throw Exception('Delay duration must be at least 1 minute');
    }

    if (overrideDuration.inMinutes < 5) {
      throw Exception('Override duration must be at least 5 minutes');
    }

    return await _repository.requestOverride(
      reason: reason,
      delayDuration: delayDuration,
      overrideDuration: overrideDuration,
    );
  }
}