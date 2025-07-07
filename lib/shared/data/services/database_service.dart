import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:injectable/injectable.dart';

@singleton
class DatabaseService {
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final String path = join(await getDatabasesPath(), 'mind_fence.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create blocked_apps table
    await db.execute('''
      CREATE TABLE blocked_apps(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        package_name TEXT NOT NULL UNIQUE,
        icon_path TEXT,
        is_blocked INTEGER NOT NULL DEFAULT 0,
        last_modified INTEGER,
        categories TEXT,
        daily_time_limit INTEGER DEFAULT 0,
        allow_notifications INTEGER DEFAULT 0
      )
    ''');

    // Create blocked_websites table
    await db.execute('''
      CREATE TABLE blocked_websites(
        id TEXT PRIMARY KEY,
        domain TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        is_blocked INTEGER NOT NULL DEFAULT 0,
        last_modified INTEGER,
        categories TEXT
      )
    ''');

    // Create focus_sessions table
    await db.execute('''
      CREATE TABLE focus_sessions(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        duration INTEGER NOT NULL,
        start_time INTEGER,
        end_time INTEGER,
        is_active INTEGER NOT NULL DEFAULT 0,
        session_type TEXT,
        blocked_apps TEXT,
        blocked_websites TEXT,
        created_at INTEGER NOT NULL
      )
    ''');

    // Create usage_stats table
    await db.execute('''
      CREATE TABLE usage_stats(
        id TEXT PRIMARY KEY,
        package_name TEXT NOT NULL,
        app_name TEXT NOT NULL,
        usage_time INTEGER NOT NULL,
        date INTEGER NOT NULL,
        launch_count INTEGER DEFAULT 0,
        last_launch INTEGER
      )
    ''');

    // Create user_preferences table
    await db.execute('''
      CREATE TABLE user_preferences(
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        type TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Create schedules table
    await db.execute('''
      CREATE TABLE schedules(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        days_of_week TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        blocked_apps TEXT,
        blocked_websites TEXT,
        created_at INTEGER NOT NULL
      )
    ''');

    // Create emergency_overrides table
    await db.execute('''
      CREATE TABLE emergency_overrides(
        id TEXT PRIMARY KEY,
        requested_at INTEGER NOT NULL,
        activated_at INTEGER,
        delay_duration_minutes INTEGER NOT NULL,
        override_duration_minutes INTEGER NOT NULL,
        reason TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 0,
        has_expired INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades
    if (oldVersion < newVersion) {
      // Add migration logic here when needed
    }
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  Future<void> deleteDatabase() async {
    final String path = join(await getDatabasesPath(), 'mind_fence.db');
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}