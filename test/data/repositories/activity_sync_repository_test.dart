import 'package:flutter_test/flutter_test.dart';
import 'package:urbantrack/data/models/activity/pending_activity_operation.dart';
import 'package:urbantrack/data/models/customer/customer_input.dart';
import 'package:urbantrack/data/models/project/project_input.dart';
import 'package:urbantrack/data/repositories/activity_sync_repository.dart';
import 'package:urbantrack/data/repositories/customer_local_store.dart';

import '../../support/memory_activity_local_store.dart';
import '../../support/stateful_customer_repository.dart';
import '../../support/stateful_project_repository.dart';

void main() {
  test(
    'replays queued activity in order and resolves a local customer',
    () async {
      final local = MemoryActivityLocalStore();
      final customers = StatefulCustomerRepository();
      final projects = StatefulProjectRepository();
      await customers.createCustomer(_customerInput, 'create-customer');
      await projects.createProject(_projectInput, 'create-project');
      await local.enqueue(
        _operation(
          requestId: 'customer-note',
          resourceType: ActivityResourceType.customer,
          resourceId: 'local:create-customer',
          type: PendingActivityOperationType.note,
          text: 'Nota del cliente',
        ),
      );
      await local.enqueue(
        _operation(
          requestId: 'project-reminder',
          resourceType: ActivityResourceType.project,
          resourceId: 'project-integration-id',
          type: PendingActivityOperationType.reminder,
          text: 'Revisar avance',
        ),
      );
      final repository = ActivitySyncRepository(
        local,
        customers,
        projects,
        _CustomerIdMap(),
      );

      final pending = await repository.getPending();
      expect(pending.map((entry) => entry.id), [
        'customer-note',
        'project-reminder',
      ]);
      expect(pending.first.dependsOnId, 'local:create-customer');

      await repository.synchronize();

      expect(customers.noteCalls, 1);
      expect(projects.reminderCalls, 1);
      expect(await local.pendingCount(), 0);
    },
  );
}

PendingActivityOperation _operation({
  required String requestId,
  required ActivityResourceType resourceType,
  required String resourceId,
  required PendingActivityOperationType type,
  required String text,
}) => PendingActivityOperation(
  requestId: requestId,
  resourceType: resourceType,
  resourceExternalId: resourceId,
  type: type,
  text: text,
  eventAtUtc: DateTime.utc(2026, 8, 18, 15),
  createdAtUtc: DateTime.utc(2026, 8, 18, 15),
);

class _CustomerIdMap implements CustomerLocalStore {
  @override
  Future<String?> serverIdForLocalId(String localCustomerId) async =>
      localCustomerId == 'local:create-customer'
      ? 'customer-integration-id'
      : null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _customerInput = CustomerInput(
  name: 'Cliente sincronizado',
  companyName: 'Empresa Demo',
  phone: '70000000',
  email: '',
  address: 'Av. Demo',
  latitude: -17.75,
  longitude: -63.18,
);

const _projectInput = ProjectInput(
  name: 'Obra sincronizada',
  description: 'Prueba de sincronización',
  customerExternalId: 'customer-integration-id',
  sellerExternalId: 'seller-id',
  estimatedAmount: null,
  startDateUtc: null,
  expectedCloseDateUtc: null,
  progressPercentage: 0,
  actualCloseDateUtc: null,
  address: 'Av. Demo',
  latitude: -17.75,
  longitude: -63.18,
);
