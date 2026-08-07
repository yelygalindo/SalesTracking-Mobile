import '../models/sync/sync_queue_entry.dart';
import '../models/workday/pending_workday_operation.dart';
import 'sync_repository.dart';
import 'workday_local_store.dart';
import 'workday_repository.dart';

class WorkdaySyncRepository implements SyncRepository {
  const WorkdaySyncRepository(this._localStore, this._workdayRepository);

  final WorkdayLocalStore _localStore;
  final WorkdayRepository _workdayRepository;

  @override
  Future<List<SyncQueueEntry>> getPending() async {
    final operations = await _localStore.readPending();
    return operations.map(_toEntry).toList(growable: false);
  }

  @override
  Future<void> synchronize() => _workdayRepository.syncPending();

  SyncQueueEntry _toEntry(PendingWorkdayOperation operation) {
    return SyncQueueEntry(
      id: operation.requestId,
      type: switch (operation.type) {
        PendingWorkdayOperationType.start => SyncQueueEntryType.workdayStart,
        PendingWorkdayOperationType.close => SyncQueueEntryType.workdayClose,
      },
      occurredAtUtc: operation.occurredAtUtc,
      createdAtUtc: operation.createdAtUtc,
      dependsOnId: operation.dependsOnRequestId,
      attemptCount: operation.attemptCount,
      lastError: operation.lastError,
    );
  }
}
