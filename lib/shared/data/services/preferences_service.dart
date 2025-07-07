import 'package:injectable/injectable.dart';
import 'package:sqflite/sqflite.dart';
import 'database_service.dart';

@injectable
class PreferencesService {
  final DatabaseService _databaseService;

  PreferencesService(this._databaseService);

  Future<void> setBool(String key, bool value) async {
    await _setPreference(key, value.toString(), 'bool');
  }

  Future<void> setString(String key, String value) async {
    await _setPreference(key, value, 'string');
  }

  Future<void> setInt(String key, int value) async {
    await _setPreference(key, value.toString(), 'int');
  }

  Future<void> setDouble(String key, double value) async {
    await _setPreference(key, value.toString(), 'double');
  }

  Future<void> setStringList(String key, List<String> value) async {
    await _setPreference(key, value.join(','), 'string_list');
  }

  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    final value = await _getPreference(key);
    if (value == null) return defaultValue;
    return value == 'true';
  }

  Future<String> getString(String key, {String defaultValue = ''}) async {
    final value = await _getPreference(key);
    return value ?? defaultValue;
  }

  Future<int> getInt(String key, {int defaultValue = 0}) async {
    final value = await _getPreference(key);
    if (value == null) return defaultValue;
    return int.tryParse(value) ?? defaultValue;
  }

  Future<double> getDouble(String key, {double defaultValue = 0.0}) async {
    final value = await _getPreference(key);
    if (value == null) return defaultValue;
    return double.tryParse(value) ?? defaultValue;
  }

  Future<List<String>> getStringList(String key, {List<String> defaultValue = const []}) async {
    final value = await _getPreference(key);
    if (value == null || value.isEmpty) return defaultValue;
    return value.split(',').where((s) => s.isNotEmpty).toList();
  }

  Future<void> remove(String key) async {
    final db = await _databaseService.database;
    await db.delete(
      'user_preferences',
      where: 'key = ?',
      whereArgs: [key],
    );
  }

  Future<void> clear() async {
    final db = await _databaseService.database;
    await db.delete('user_preferences');
  }

  Future<bool> containsKey(String key) async {
    final value = await _getPreference(key);
    return value != null;
  }

  Future<Set<String>> getKeys() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_preferences',
      columns: ['key'],
    );
    return maps.map((map) => map['key'] as String).toSet();
  }

  Future<void> _setPreference(String key, String value, String type) async {
    final db = await _databaseService.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    await db.insert(
      'user_preferences',
      {
        'key': key,
        'value': value,
        'type': type,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> _getPreference(String key) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_preferences',
      where: 'key = ?',
      whereArgs: [key],
    );
    
    if (maps.isEmpty) return null;
    return maps.first['value'] as String?;
  }
}