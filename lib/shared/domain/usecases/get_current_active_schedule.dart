import 'package:injectable/injectable.dart';
import '../entities/schedule.dart';
import '../repositories/schedule_repository.dart';

@injectable
class GetCurrentActiveSchedule {
  final ScheduleRepository _repository;

  GetCurrentActiveSchedule(this._repository);

  Future<Schedule?> call() async {
    return await _repository.getCurrentActiveSchedule();
  }
}