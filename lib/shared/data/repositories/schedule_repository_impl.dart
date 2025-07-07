import 'package:injectable/injectable.dart';
import '../datasources/schedule_datasource.dart';
import '../models/schedule_model.dart';
import '../../domain/entities/schedule.dart';
import '../../domain/repositories/schedule_repository.dart';

@Injectable(as: ScheduleRepository)
class ScheduleRepositoryImpl implements ScheduleRepository {
  final ScheduleDataSource _dataSource;

  ScheduleRepositoryImpl(this._dataSource);

  @override
  Future<List<Schedule>> getSchedules() async {
    final models = await _dataSource.getSchedules();
    return models.map((model) => model.toDomain()).toList();
  }

  @override
  Future<Schedule> getSchedule(String id) async {
    final model = await _dataSource.getSchedule(id);
    return model.toDomain();
  }

  @override
  Future<void> addSchedule(Schedule schedule) async {
    final model = ScheduleModel.fromDomain(schedule);
    await _dataSource.addSchedule(model);
  }

  @override
  Future<void> updateSchedule(Schedule schedule) async {
    final model = ScheduleModel.fromDomain(schedule);
    await _dataSource.updateSchedule(model);
  }

  @override
  Future<void> removeSchedule(String id) async {
    await _dataSource.removeSchedule(id);
  }

  @override
  Future<void> toggleSchedule(String id) async {
    final schedule = await getSchedule(id);
    final updatedSchedule = schedule.copyWith(isActive: !schedule.isActive);
    await updateSchedule(updatedSchedule);
  }

  @override
  Future<List<Schedule>> getActiveSchedules() async {
    final models = await _dataSource.getActiveSchedules();
    return models.map((model) => model.toDomain()).toList();
  }

  @override
  Future<bool> hasActiveSchedule() async {
    final activeSchedules = await getActiveSchedules();
    return activeSchedules.any((schedule) => schedule.isActiveNow());
  }

  @override
  Future<Schedule?> getCurrentActiveSchedule() async {
    final activeSchedules = await getActiveSchedules();
    try {
      return activeSchedules.firstWhere((schedule) => schedule.isActiveNow());
    } catch (e) {
      return null;
    }
  }
}