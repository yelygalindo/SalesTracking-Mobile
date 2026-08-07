import '../models/customer/pending_customer_operation.dart';
import '../models/sync/sync_queue_entry.dart';
import 'customer_local_store.dart';
import 'sync_repository.dart';

abstract interface class CustomerSyncController {
  Future<void> syncPending();
}

class CustomerSyncRepository implements SyncRepository {
  const CustomerSyncRepository(this._localStore, this._customerRepository);

  final CustomerLocalStore _localStore;
  final CustomerSyncController _customerRepository;

  @override
  Future<List<SyncQueueEntry>> getPending() async {
    final operations = await _localStore.readPending();
    return operations.map(_toEntry).toList(growable: false);
  }

  @override
  Future<void> synchronize() => _customerRepository.syncPending();

  SyncQueueEntry _toEntry(PendingCustomerOperation operation) {
    return SyncQueueEntry(
      id: operation.requestId,
      type: switch (operation.type) {
        PendingCustomerOperationType.create =>
          SyncQueueEntryType.customerCreate,
      },
      occurredAtUtc: operation.createdAtUtc,
      createdAtUtc: operation.createdAtUtc,
      attemptCount: operation.attemptCount,
      lastError: operation.lastError,
    );
  }
}
