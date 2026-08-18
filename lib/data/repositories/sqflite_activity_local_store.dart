import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../models/activity/pending_activity_operation.dart';
import '../models/project/project_note.dart';
import '../models/project/project_reminder.dart';
import '../storage/app_database.dart';
import 'activity_local_store.dart';

class SqfliteActivityLocalStore implements ActivityLocalStore {
  SqfliteActivityLocalStore(AppDatabase appDatabase)
    : _database = appDatabase.database;

  final Future<Database> _database;

  @override
  Future<void> enqueue(PendingActivityOperation operation) async {
    final database = await _database;
    await database.insert(
      'activity_sync_operations',
      operation.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  @override
  Future<List<PendingActivityOperation>> readPending({
    ActivityResourceType? resourceType,
    String? resourceExternalId,
  }) async {
    final database = await _database;
    final clauses = <String>[];
    final args = <Object?>[];
    if (resourceType != null) {
      clauses.add('resource_type = ?');
      args.add(resourceType.name);
    }
    if (resourceExternalId?.trim().isNotEmpty == true) {
      clauses.add('resource_external_id = ?');
      args.add(resourceExternalId!.trim());
    }
    final rows = await database.query(
      'activity_sync_operations',
      where: clauses.isEmpty ? null : clauses.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'sequence ASC',
    );
    return rows.map(PendingActivityOperation.fromMap).toList(growable: false);
  }

  @override
  Future<int> pendingCount() async {
    final database = await _database;
    final rows = await database.rawQuery(
      'SELECT COUNT(*) AS total FROM activity_sync_operations',
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  @override
  Future<void> markSynced(String requestId) async {
    final database = await _database;
    await database.delete(
      'activity_sync_operations',
      where: 'request_id = ?',
      whereArgs: [requestId],
    );
  }

  @override
  Future<void> recordFailure(String requestId, String message) async {
    final database = await _database;
    await database.rawUpdate(
      '''
        UPDATE activity_sync_operations
        SET attempt_count = attempt_count + 1, last_error = ?
        WHERE request_id = ?
      ''',
      [message, requestId],
    );
  }

  @override
  Future<void> cacheProjectNotes(
    String projectExternalId,
    List<ProjectNote> notes,
  ) async {
    final database = await _database;
    await database.transaction((transaction) async {
      await transaction.delete(
        'project_note_cache',
        where: 'project_external_id = ?',
        whereArgs: [projectExternalId],
      );
      for (final note in notes) {
        await transaction.insert('project_note_cache', {
          'external_id': note.externalId,
          'project_external_id': projectExternalId,
          'payload': jsonEncode(note.toJson()),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  @override
  Future<List<ProjectNote>> readProjectNotes(String projectExternalId) async {
    final database = await _database;
    final rows = await database.query(
      'project_note_cache',
      columns: ['payload'],
      where: 'project_external_id = ?',
      whereArgs: [projectExternalId],
    );
    return rows
        .map((row) {
          final decoded = jsonDecode(row['payload'] as String);
          return ProjectNote.fromJson(decoded as Map<String, dynamic>);
        })
        .toList(growable: false);
  }

  @override
  Future<void> cacheProjectReminders(
    String projectExternalId,
    List<ProjectReminder> reminders,
  ) async {
    final database = await _database;
    await database.transaction((transaction) async {
      await transaction.delete(
        'project_reminder_cache',
        where: 'project_external_id = ?',
        whereArgs: [projectExternalId],
      );
      for (final reminder in reminders) {
        await transaction.insert('project_reminder_cache', {
          'external_id': reminder.externalId ?? 'server:${reminder.id}',
          'project_external_id': projectExternalId,
          'payload': jsonEncode(reminder.toJson()),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  @override
  Future<List<ProjectReminder>> readProjectReminders(
    String projectExternalId,
  ) async {
    final database = await _database;
    final rows = await database.query(
      'project_reminder_cache',
      columns: ['payload'],
      where: 'project_external_id = ?',
      whereArgs: [projectExternalId],
    );
    return rows
        .map((row) {
          final decoded = jsonDecode(row['payload'] as String);
          return ProjectReminder.fromJson(decoded as Map<String, dynamic>);
        })
        .toList(growable: false);
  }
}
