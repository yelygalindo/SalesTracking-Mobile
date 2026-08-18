import '../models/activity/pending_activity_operation.dart';
import '../models/project/project_note.dart';
import '../models/project/project_reminder.dart';

abstract interface class ActivityLocalStore {
  Future<void> enqueue(PendingActivityOperation operation);

  Future<List<PendingActivityOperation>> readPending({
    ActivityResourceType? resourceType,
    String? resourceExternalId,
  });

  Future<int> pendingCount();

  Future<void> markSynced(String requestId);

  Future<void> recordFailure(String requestId, String message);

  Future<void> cacheProjectNotes(
    String projectExternalId,
    List<ProjectNote> notes,
  );

  Future<List<ProjectNote>> readProjectNotes(String projectExternalId);

  Future<void> cacheProjectReminders(
    String projectExternalId,
    List<ProjectReminder> reminders,
  );

  Future<List<ProjectReminder>> readProjectReminders(String projectExternalId);
}
