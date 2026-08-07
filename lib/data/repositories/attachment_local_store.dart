import '../models/attachment/pending_attachment_operation.dart';

abstract interface class AttachmentLocalStore {
  Future<void> enqueue(PendingAttachmentOperation operation);

  Future<List<PendingAttachmentOperation>> readPending();

  Future<int> pendingCount();

  Future<void> markSynced(String requestId);

  Future<void> recordFailure(String requestId, String message);
}
