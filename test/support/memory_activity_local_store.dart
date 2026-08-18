import 'package:urbantrack/data/models/activity/pending_activity_operation.dart';
import 'package:urbantrack/data/models/project/project_note.dart';
import 'package:urbantrack/data/models/project/project_reminder.dart';
import 'package:urbantrack/data/repositories/activity_local_store.dart';

class MemoryActivityLocalStore implements ActivityLocalStore {
  final List<PendingActivityOperation> operations = [];
  final Map<String, List<ProjectNote>> projectNotes = {};
  final Map<String, List<ProjectReminder>> projectReminders = {};

  @override
  Future<void> enqueue(PendingActivityOperation operation) async {
    if (!operations.any((item) => item.requestId == operation.requestId)) {
      operations.add(operation);
    }
  }

  @override
  Future<List<PendingActivityOperation>> readPending({
    ActivityResourceType? resourceType,
    String? resourceExternalId,
  }) async => operations
      .where(
        (operation) =>
            (resourceType == null || operation.resourceType == resourceType) &&
            (resourceExternalId == null ||
                operation.resourceExternalId == resourceExternalId),
      )
      .toList(growable: false);

  @override
  Future<int> pendingCount() async => operations.length;

  @override
  Future<void> markSynced(String requestId) async {
    operations.removeWhere((operation) => operation.requestId == requestId);
  }

  @override
  Future<void> recordFailure(String requestId, String message) async {
    final index = operations.indexWhere(
      (operation) => operation.requestId == requestId,
    );
    if (index < 0) return;
    final operation = operations[index];
    operations[index] = PendingActivityOperation(
      requestId: operation.requestId,
      resourceType: operation.resourceType,
      resourceExternalId: operation.resourceExternalId,
      type: operation.type,
      eventAtUtc: operation.eventAtUtc,
      createdAtUtc: operation.createdAtUtc,
      text: operation.text,
      assignedToId: operation.assignedToId,
      reminderExternalId: operation.reminderExternalId,
      attemptCount: operation.attemptCount + 1,
      lastError: message,
    );
  }

  @override
  Future<void> cacheProjectNotes(
    String projectExternalId,
    List<ProjectNote> notes,
  ) async {
    projectNotes[projectExternalId] = List.of(notes);
  }

  @override
  Future<List<ProjectNote>> readProjectNotes(String projectExternalId) async =>
      List.of(projectNotes[projectExternalId] ?? const []);

  @override
  Future<void> cacheProjectReminders(
    String projectExternalId,
    List<ProjectReminder> reminders,
  ) async {
    projectReminders[projectExternalId] = List.of(reminders);
  }

  @override
  Future<List<ProjectReminder>> readProjectReminders(
    String projectExternalId,
  ) async => List.of(projectReminders[projectExternalId] ?? const []);
}
