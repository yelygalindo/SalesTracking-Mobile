import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../models/workday/pending_workday_operation.dart';
import '../models/workday/workday.dart';
import '../storage/app_database.dart';
import 'workday_local_store.dart';

class SqfliteWorkdayLocalStore implements WorkdayLocalStore {
  SqfliteWorkdayLocalStore(AppDatabase appDatabase)
    : _database = appDatabase.database;

  final Future<Database> _database;

  @override
  Future<Workday?> readCurrent() async {
    final database = await _database;
    final rows = await database.query(
      'workday_cache',
      columns: ['payload'],
      where: 'id = 1',
      limit: 1,
    );
    if (rows.isEmpty) return null;

    try {
      final decoded = jsonDecode(rows.first['payload'] as String);
      if (decoded is! Map<String, dynamic>) return null;
      return Workday.fromJson(decoded);
    } on FormatException {
      await database.delete('workday_cache', where: 'id = 1');
      return null;
    }
  }

  @override
  Future<void> writeCurrent(Workday? workday) async {
    final database = await _database;
    if (workday == null) {
      await database.delete('workday_cache', where: 'id = 1');
      return;
    }
    await database.insert('workday_cache', {
      'id': 1,
      'payload': jsonEncode(workday.toJson()),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> enqueue(
    PendingWorkdayOperation operation, {
    required Workday current,
  }) async {
    final database = await _database;
    await database.transaction((transaction) async {
      await transaction.insert(
        'workday_sync_operations',
        operation.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      await transaction.insert('workday_cache', {
        'id': 1,
        'payload': jsonEncode(current.toJson()),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  @override
  Future<List<PendingWorkdayOperation>> readPending() async {
    final database = await _database;
    final rows = await database.query(
      'workday_sync_operations',
      orderBy: 'sequence ASC',
    );
    return rows.map(PendingWorkdayOperation.fromMap).toList(growable: false);
  }

  @override
  Future<int> pendingCount() async {
    final database = await _database;
    final rows = await database.rawQuery(
      'SELECT COUNT(*) AS total FROM workday_sync_operations',
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  @override
  Future<String?> serverIdForLocalId(String localWorkdayId) async {
    final database = await _database;
    final rows = await database.query(
      'workday_id_map',
      columns: ['server_workday_id'],
      where: 'local_workday_id = ?',
      whereArgs: [localWorkdayId],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['server_workday_id'] as String?;
  }

  @override
  Future<void> markSynced(
    String requestId, {
    String? localWorkdayId,
    String? serverWorkdayId,
  }) async {
    final database = await _database;
    await database.transaction((transaction) async {
      if (localWorkdayId != null && serverWorkdayId != null) {
        await transaction.insert('workday_id_map', {
          'local_workday_id': localWorkdayId,
          'server_workday_id': serverWorkdayId,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await transaction.delete(
        'workday_sync_operations',
        where: 'request_id = ?',
        whereArgs: [requestId],
      );
    });
  }

  @override
  Future<void> recordFailure(String requestId, String message) async {
    final database = await _database;
    await database.rawUpdate(
      '''
        UPDATE workday_sync_operations
        SET attempt_count = attempt_count + 1, last_error = ?
        WHERE request_id = ?
      ''',
      [message, requestId],
    );
  }
}
