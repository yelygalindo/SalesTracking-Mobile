import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../models/visit/current_visit.dart';
import '../models/visit/pending_visit_operation.dart';
import '../storage/app_database.dart';
import 'visit_local_store.dart';

class SqfliteVisitLocalStore implements VisitLocalStore {
  SqfliteVisitLocalStore(AppDatabase appDatabase)
    : _database = appDatabase.database;

  final Future<Database> _database;

  @override
  Future<CurrentVisit?> readCurrent() async {
    final database = await _database;
    final rows = await database.query(
      'visit_cache',
      columns: ['payload'],
      where: 'id = 1',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    try {
      final payload = jsonDecode(rows.first['payload'] as String);
      return payload is Map<String, dynamic>
          ? CurrentVisit.fromJson(payload)
          : null;
    } on FormatException {
      await database.delete('visit_cache', where: 'id = 1');
      return null;
    }
  }

  @override
  Future<void> writeCurrent(CurrentVisit? visit) async {
    final database = await _database;
    if (visit == null) {
      await database.delete('visit_cache', where: 'id = 1');
      return;
    }
    await database.insert('visit_cache', {
      'id': 1,
      'payload': jsonEncode(visit.toJson()),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> enqueue(
    PendingVisitOperation operation, {
    required CurrentVisit? current,
  }) async {
    final database = await _database;
    await database.transaction((transaction) async {
      await transaction.insert(
        'visit_sync_operations',
        operation.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      if (current == null) {
        await transaction.delete('visit_cache', where: 'id = 1');
      } else {
        await transaction.insert('visit_cache', {
          'id': 1,
          'payload': jsonEncode(current.toJson()),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  @override
  Future<List<PendingVisitOperation>> readPending() async {
    final database = await _database;
    final rows = await database.query(
      'visit_sync_operations',
      orderBy: 'sequence ASC',
    );
    return rows.map(PendingVisitOperation.fromMap).toList(growable: false);
  }

  @override
  Future<int> pendingCount() async {
    final database = await _database;
    final rows = await database.rawQuery(
      'SELECT COUNT(*) AS total FROM visit_sync_operations',
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  @override
  Future<String?> serverIdForLocalId(String localVisitId) async {
    final database = await _database;
    final rows = await database.query(
      'visit_id_map',
      columns: ['server_visit_id'],
      where: 'local_visit_id = ?',
      whereArgs: [localVisitId],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['server_visit_id'] as String?;
  }

  @override
  Future<void> markSynced(
    String requestId, {
    String? localVisitId,
    String? serverVisitId,
  }) async {
    final database = await _database;
    await database.transaction((transaction) async {
      if (localVisitId != null && serverVisitId != null) {
        await transaction.insert('visit_id_map', {
          'local_visit_id': localVisitId,
          'server_visit_id': serverVisitId,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        final currentRows = await transaction.query(
          'visit_cache',
          columns: ['payload'],
          where: 'id = 1',
          limit: 1,
        );
        if (currentRows.isNotEmpty) {
          final decoded = jsonDecode(currentRows.first['payload'] as String);
          if (decoded is Map<String, dynamic> &&
              decoded['visitExternalId'] == localVisitId) {
            decoded['visitExternalId'] = serverVisitId;
            await transaction.update('visit_cache', {
              'payload': jsonEncode(decoded),
            }, where: 'id = 1');
          }
        }
      }
      await transaction.delete(
        'visit_sync_operations',
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
        UPDATE visit_sync_operations
        SET attempt_count = attempt_count + 1, last_error = ?
        WHERE request_id = ?
      ''',
      [message, requestId],
    );
  }
}
