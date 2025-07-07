import 'package:injectable/injectable.dart';
import '../models/emergency_override_model.dart';
import '../services/database_service.dart';

abstract class EmergencyOverrideDataSource {
  Future<EmergencyOverrideModel> createOverride(EmergencyOverrideModel override);
  Future<void> updateOverride(EmergencyOverrideModel override);
  Future<EmergencyOverrideModel?> getCurrentOverride();
  Future<List<EmergencyOverrideModel>> getOverrideHistory();
  Future<void> deleteOverride(String id);
  Future<List<EmergencyOverrideModel>> getExpiredOverrides();
}

@Injectable(as: EmergencyOverrideDataSource)
class EmergencyOverrideDataSourceImpl implements EmergencyOverrideDataSource {
  final DatabaseService _databaseService;

  EmergencyOverrideDataSourceImpl(this._databaseService);

  @override
  Future<EmergencyOverrideModel> createOverride(EmergencyOverrideModel override) async {
    final db = await _databaseService.database;
    await db.insert('emergency_overrides', override.toMap());
    return override;
  }

  @override
  Future<void> updateOverride(EmergencyOverrideModel override) async {
    final db = await _databaseService.database;
    await db.update(
      'emergency_overrides',
      override.toMap(),
      where: 'id = ?',
      whereArgs: [override.id],
    );
  }

  @override
  Future<EmergencyOverrideModel?> getCurrentOverride() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'emergency_overrides',
      where: 'is_active = ? OR (has_expired = ? AND is_active = ?)',
      whereArgs: [1, 0, 0],
      orderBy: 'requested_at DESC',
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return EmergencyOverrideModel.fromMap(maps.first);
  }

  @override
  Future<List<EmergencyOverrideModel>> getOverrideHistory() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'emergency_overrides',
      orderBy: 'requested_at DESC',
      limit: 50, // Last 50 overrides
    );
    return maps.map((map) => EmergencyOverrideModel.fromMap(map)).toList();
  }

  @override
  Future<void> deleteOverride(String id) async {
    final db = await _databaseService.database;
    await db.delete(
      'emergency_overrides',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<EmergencyOverrideModel>> getExpiredOverrides() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'emergency_overrides',
      where: 'has_expired = ?',
      whereArgs: [1],
      orderBy: 'requested_at DESC',
    );
    return maps.map((map) => EmergencyOverrideModel.fromMap(map)).toList();
  }
}