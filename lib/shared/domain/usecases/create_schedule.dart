import 'package:injectable/injectable.dart';
import '../entities/schedule.dart';
import '../repositories/schedule_repository.dart';

@injectable
class CreateSchedule {
  final ScheduleRepository _repository;

  CreateSchedule(this._repository);

  Future<void> call({
    required String name,
    required String startTime,
    required String endTime,
    required List<int> daysOfWeek,
    required List<String> blockedApps,
    required List<String> blockedWebsites,
  }) async {
    final schedule = Schedule(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      startTime: startTime,
      endTime: endTime,
      daysOfWeek: daysOfWeek,
      isActive: true,
      blockedApps: blockedApps,
      blockedWebsites: blockedWebsites,
      createdAt: DateTime.now(),
    );

    await _repository.addSchedule(schedule);
  }
}