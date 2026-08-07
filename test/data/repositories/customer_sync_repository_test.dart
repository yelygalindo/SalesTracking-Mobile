import 'package:flutter_test/flutter_test.dart';
import 'package:urbantrack/data/models/customer/customer_detail.dart';
import 'package:urbantrack/data/models/customer/customer_input.dart';
import 'package:urbantrack/data/models/customer/customer_page.dart';
import 'package:urbantrack/data/models/customer/customer_status.dart';
import 'package:urbantrack/data/models/customer/customer_summary.dart';
import 'package:urbantrack/data/models/customer/pending_customer_operation.dart';
import 'package:urbantrack/data/models/sync/sync_queue_entry.dart';
import 'package:urbantrack/data/repositories/customer_local_store.dart';
import 'package:urbantrack/data/repositories/customer_sync_repository.dart';

void main() {
  test(
    'maps pending customer creation and delegates synchronization',
    () async {
      final operation = PendingCustomerOperation(
        requestId: 'customer-request',
        localCustomerId: 'local:customer-request',
        type: PendingCustomerOperationType.create,
        input: _input,
        createdAtUtc: DateTime.utc(2026, 8, 7, 16),
        attemptCount: 2,
        lastError: 'Temporal',
      );
      final controller = _RecordingCustomerSyncController();
      final repository = CustomerSyncRepository(
        _PendingCustomerLocalStore(operation),
        controller,
      );

      final entries = await repository.getPending();
      await repository.synchronize();

      expect(entries.single.type, SyncQueueEntryType.customerCreate);
      expect(entries.single.attemptCount, 2);
      expect(entries.single.lastError, 'Temporal');
      expect(controller.syncCalls, 1);
    },
  );
}

const _input = CustomerInput(
  name: 'Cliente',
  companyName: 'Empresa',
  phone: '999',
  email: 'client@example.test',
  address: '',
  latitude: null,
  longitude: null,
);

class _RecordingCustomerSyncController implements CustomerSyncController {
  int syncCalls = 0;

  @override
  Future<void> syncPending() async => syncCalls += 1;
}

class _PendingCustomerLocalStore implements CustomerLocalStore {
  const _PendingCustomerLocalStore(this.operation);

  final PendingCustomerOperation operation;

  @override
  Future<List<PendingCustomerOperation>> readPending() async => [operation];

  @override
  Future<int> pendingCount() async => 1;

  @override
  Future<void> cacheCustomers(List<CustomerSummary> customers) {
    throw UnimplementedError();
  }

  @override
  Future<void> cacheDetail(CustomerDetail customer) {
    throw UnimplementedError();
  }

  @override
  Future<void> cacheStatuses(List<CustomerStatus> statuses) {
    throw UnimplementedError();
  }

  @override
  Future<void> enqueueCreate(
    PendingCustomerOperation operation, {
    required CustomerSummary summary,
    required CustomerDetail detail,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> markCreateSynced(
    String requestId, {
    required String localCustomerId,
    required String serverCustomerId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<CustomerDetail?> readDetail(String externalId) {
    throw UnimplementedError();
  }

  @override
  Future<CustomerPage> readCustomers({
    String? status,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<CustomerSummary>> readPendingCustomers() {
    throw UnimplementedError();
  }

  @override
  Future<List<CustomerStatus>> readStatuses() {
    throw UnimplementedError();
  }

  @override
  Future<void> recordFailure(String requestId, String message) {
    throw UnimplementedError();
  }

  @override
  Future<String?> serverIdForLocalId(String localCustomerId) {
    throw UnimplementedError();
  }
}
