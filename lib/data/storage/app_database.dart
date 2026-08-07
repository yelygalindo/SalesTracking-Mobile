import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase({Future<Database>? database})
    : database = database ?? _openDatabase();

  final Future<Database> database;

  static Future<Database> _openDatabase() async {
    final root = await getDatabasesPath();
    return openDatabase(
      path.join(root, 'urbantrack.db'),
      version: 4,
      onConfigure: (database) => database.execute('PRAGMA foreign_keys = ON'),
      onCreate: (database, version) async {
        await _createWorkdayTables(database);
        await _createCustomerTables(database);
        await _createVisitTables(database);
        await _createAttachmentTables(database);
      },
      onUpgrade: (database, oldVersion, newVersion) async {
        if (oldVersion < 2) await _createCustomerTables(database);
        if (oldVersion < 3) await _createVisitTables(database);
        if (oldVersion < 4) await _createAttachmentTables(database);
      },
    );
  }

  static Future<void> _createWorkdayTables(Database database) async {
    await database.execute('''
      CREATE TABLE workday_cache (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        payload TEXT NOT NULL
      )
    ''');
    await database.execute('''
      CREATE TABLE workday_sync_operations (
        sequence INTEGER PRIMARY KEY AUTOINCREMENT,
        request_id TEXT NOT NULL UNIQUE,
        local_workday_id TEXT NOT NULL,
        operation_type TEXT NOT NULL,
        occurred_at_utc TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        accuracy_meters REAL NOT NULL,
        note TEXT,
        server_workday_id TEXT,
        depends_on_request_id TEXT,
        attempt_count INTEGER NOT NULL DEFAULT 0,
        last_error TEXT,
        created_at_utc TEXT NOT NULL
      )
    ''');
    await database.execute('''
      CREATE TABLE workday_id_map (
        local_workday_id TEXT PRIMARY KEY,
        server_workday_id TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _createCustomerTables(Database database) async {
    await database.execute('''
      CREATE TABLE customer_summary_cache (
        external_id TEXT PRIMARY KEY,
        payload TEXT NOT NULL,
        is_pending INTEGER NOT NULL DEFAULT 0,
        updated_at_utc TEXT NOT NULL
      )
    ''');
    await database.execute('''
      CREATE TABLE customer_detail_cache (
        external_id TEXT PRIMARY KEY,
        payload TEXT NOT NULL
      )
    ''');
    await database.execute('''
      CREATE TABLE customer_status_cache (
        value INTEGER PRIMARY KEY,
        payload TEXT NOT NULL
      )
    ''');
    await database.execute('''
      CREATE TABLE customer_sync_operations (
        sequence INTEGER PRIMARY KEY AUTOINCREMENT,
        request_id TEXT NOT NULL UNIQUE,
        local_customer_id TEXT NOT NULL,
        operation_type TEXT NOT NULL,
        payload TEXT NOT NULL,
        attempt_count INTEGER NOT NULL DEFAULT 0,
        last_error TEXT,
        created_at_utc TEXT NOT NULL
      )
    ''');
    await database.execute('''
      CREATE TABLE customer_id_map (
        local_customer_id TEXT PRIMARY KEY,
        server_customer_id TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _createVisitTables(Database database) async {
    await database.execute('''
      CREATE TABLE visit_cache (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        payload TEXT NOT NULL
      )
    ''');
    await database.execute('''
      CREATE TABLE visit_sync_operations (
        sequence INTEGER PRIMARY KEY AUTOINCREMENT,
        request_id TEXT NOT NULL UNIQUE,
        local_visit_id TEXT NOT NULL,
        operation_type TEXT NOT NULL,
        target_type TEXT NOT NULL,
        target_external_id TEXT NOT NULL,
        target_name TEXT NOT NULL,
        occurred_at_utc TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        accuracy_meters REAL NOT NULL,
        note TEXT,
        result TEXT,
        server_visit_id TEXT,
        depends_on_request_id TEXT,
        attempt_count INTEGER NOT NULL DEFAULT 0,
        last_error TEXT,
        created_at_utc TEXT NOT NULL
      )
    ''');
    await database.execute('''
      CREATE TABLE visit_id_map (
        local_visit_id TEXT PRIMARY KEY,
        server_visit_id TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _createAttachmentTables(Database database) async {
    await database.execute('''
      CREATE TABLE attachment_sync_operations (
        sequence INTEGER PRIMARY KEY AUTOINCREMENT,
        request_id TEXT NOT NULL UNIQUE,
        project_external_id TEXT NOT NULL,
        visit_external_id TEXT,
        file_path TEXT NOT NULL,
        file_name TEXT NOT NULL,
        content_type TEXT NOT NULL,
        size_bytes INTEGER NOT NULL,
        attachment_type TEXT NOT NULL,
        caption TEXT,
        is_cover INTEGER NOT NULL DEFAULT 0,
        attempt_count INTEGER NOT NULL DEFAULT 0,
        last_error TEXT,
        created_at_utc TEXT NOT NULL
      )
    ''');
  }
}
