import 'package:injectable/injectable.dart';
import '../models/schedule_model.dart';
import '../services/database_service.dart';

abstract class ScheduleDataSource {
  Future<List<ScheduleModel>> getSchedules();
  Future<ScheduleModel> getSchedule(String id);
  Future<void> addSchedule(ScheduleModel schedule);
  Future<void> updateSchedule(ScheduleModel schedule);
  Future<void> removeSchedule(String id);
  Future<List<ScheduleModel>> getActiveSchedules();
}

@Injectable(as: ScheduleDataSource)
class ScheduleDataSourceImpl implements ScheduleDataSource {
  final DatabaseService _databaseService;

  ScheduleDataSourceImpl(this._databaseService);

  @override
  Future<List<ScheduleModel>> getSchedules() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'schedules',
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => ScheduleModel.fromMap(map)).toList();
  }

  @override
  Future<ScheduleModel> getSchedule(String id) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'schedules',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isEmpty) {
      throw Exception('Schedule not found with id: $id');
    }
    
    return ScheduleModel.fromMap(maps.first);
  }

  @override
  Future<void> addSchedule(ScheduleModel schedule) async {
    final db = await _databaseService.database;
    await db.insert('schedules', schedule.toMap());
  }

  @override
  Future<void> updateSchedule(ScheduleModel schedule) async {
    final db = await _databaseService.database;
    await db.update(
      'schedules',
      schedule.toMap(),
      where: 'id = ?',
      whereArgs: [schedule.id],
    );
  }

  @override
  Future<void> removeSchedule(String id) async {
    final db = await _databaseService.database;
    await db.delete(
      'schedules',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<ScheduleModel>> getActiveSchedules() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'schedules',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => ScheduleModel.fromMap(map)).toList();
  }
}