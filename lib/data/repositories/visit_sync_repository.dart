import '../models/sync/sync_queue_entry.dart';
import '../models/visit/pending_visit_operation.dart';
import '../models/visit/visit_target_type.dart';
import 'sync_repository.dart';
import 'visit_local_store.dart';
import 'visit_repository.dart';

class VisitSyncRepository implements SyncRepository {
  const VisitSyncRepository(this._local, this._visits);

  final VisitLocalStore _local;
  final VisitRepository _visits;

  @override
  Future<List<SyncQueueEntry>> getPending() async {
    final operations = await _local.readPending();
    return operations.map(_entry).toList(growable: false);
  }

  @override
  Future<void> synchronize() => _visits.syncPending();

  SyncQueueEntry _entry(PendingVisitOperation operation) => SyncQueueEntry(
    id: operation.requestId,
    type: switch ((operation.targetType, operation.type)) {
      (VisitTargetType.customer, PendingVisitOperationType.checkIn) =>
        SyncQueueEntryType.customerVisitCheckIn,
      (VisitTargetType.customer, PendingVisitOperationType.checkOut) =>
        SyncQueueEntryType.customerVisitCheckOut,
      (VisitTargetType.project, PendingVisitOperationType.checkIn) =>
        SyncQueueEntryType.projectVisitCheckIn,
      (VisitTargetType.project, PendingVisitOperationType.checkOut) =>
        SyncQueueEntryType.projectVisitCheckOut,
    },
    occurredAtUtc: operation.occurredAtUtc,
    createdAtUtc: operation.createdAtUtc,
    dependsOnId: operation.dependsOnRequestId,
    attemptCount: operation.attemptCount,
    lastError: operation.lastError,
  );
}
