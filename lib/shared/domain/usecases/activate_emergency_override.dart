import 'package:injectable/injectable.dart';
import '../repositories/emergency_override_repository.dart';

@injectable
class ActivateEmergencyOverride {
  final EmergencyOverrideRepository _repository;

  ActivateEmergencyOverride(this._repository);

  Future<void> call(String overrideId) async {
    if (overrideId.isEmpty) {
      throw Exception('Override ID cannot be empty');
    }

    await _repository.activateOverride(overrideId);
  }
}