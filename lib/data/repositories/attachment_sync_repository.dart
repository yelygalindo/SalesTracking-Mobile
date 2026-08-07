import '../models/sync/sync_queue_entry.dart';
import 'attachment_local_store.dart';
import 'project_attachment_repository.dart';
import 'sync_repository.dart';

class AttachmentSyncRepository implements SyncRepository {
  const AttachmentSyncRepository(this._local, this._attachments);

  final AttachmentLocalStore _local;
  final ProjectAttachmentRepository _attachments;

  @override
  Future<List<SyncQueueEntry>> getPending() async {
    final operations = await _local.readPending();
    return operations
        .map(
          (operation) => SyncQueueEntry(
            id: operation.requestId,
            type: SyncQueueEntryType.projectPhoto,
            occurredAtUtc: operation.createdAtUtc,
            createdAtUtc: operation.createdAtUtc,
            dependsOnId: operation.visitExternalId?.startsWith('local:') == true
                ? operation.visitExternalId!.substring('local:'.length)
                : null,
            attemptCount: operation.attemptCount,
            lastError: operation.lastError,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> synchronize() => _attachments.syncPending();
}
