import 'package:sqflite/sqflite.dart';

import '../models/attachment/pending_attachment_operation.dart';
import '../storage/app_database.dart';
import 'attachment_local_store.dart';

class SqfliteAttachmentLocalStore implements AttachmentLocalStore {
  SqfliteAttachmentLocalStore(AppDatabase appDatabase)
    : _database = appDatabase.database;

  final Future<Database> _database;

  @override
  Future<void> enqueue(PendingAttachmentOperation operation) async {
    final database = await _database;
    await database.insert(
      'attachment_sync_operations',
      operation.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  @override
  Future<List<PendingAttachmentOperation>> readPending() async {
    final database = await _database;
    final rows = await database.query(
      'attachment_sync_operations',
      orderBy: 'sequence ASC',
    );
    return rows.map(PendingAttachmentOperation.fromMap).toList(growable: false);
  }

  @override
  Future<int> pendingCount() async {
    final database = await _database;
    final rows = await database.rawQuery(
      'SELECT COUNT(*) AS total FROM attachment_sync_operations',
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  @override
  Future<void> markSynced(String requestId) async {
    final database = await _database;
    await database.delete(
      'attachment_sync_operations',
      where: 'request_id = ?',
      whereArgs: [requestId],
    );
  }

  @override
  Future<void> recordFailure(String requestId, String message) async {
    final database = await _database;
    await database.rawUpdate(
      '''
        UPDATE attachment_sync_operations
        SET attempt_count = attempt_count + 1, last_error = ?
        WHERE request_id = ?
      ''',
      [message, requestId],
    );
  }
}
