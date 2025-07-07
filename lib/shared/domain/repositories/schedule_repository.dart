import '../entities/schedule.dart';

abstract class ScheduleRepository {
  Future<List<Schedule>> getSchedules();
  Future<Schedule> getSchedule(String id);
  Future<void> addSchedule(Schedule schedule);
  Future<void> updateSchedule(Schedule schedule);
  Future<void> removeSchedule(String id);
  Future<void> toggleSchedule(String id);
  Future<List<Schedule>> getActiveSchedules();
  Future<bool> hasActiveSchedule();
  Future<Schedule?> getCurrentActiveSchedule();
}