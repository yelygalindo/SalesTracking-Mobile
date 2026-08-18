import 'package:flutter_test/flutter_test.dart';
import 'package:urbantrack/data/models/common/resource_creation_result.dart';
import 'package:urbantrack/data/models/customer/customer_detail.dart';
import 'package:urbantrack/data/models/customer/customer_input.dart';
import 'package:urbantrack/data/models/customer/customer_page.dart';
import 'package:urbantrack/data/models/customer/customer_status.dart';
import 'package:urbantrack/data/models/customer/customer_summary.dart';
import 'package:urbantrack/data/models/customer/pending_customer_operation.dart';
import 'package:urbantrack/data/repositories/customer_local_store.dart';
import 'package:urbantrack/data/repositories/customer_repository.dart';
import 'package:urbantrack/data/repositories/offline_first_customer_repository.dart';
import 'package:urbantrack/data/services/api_exception.dart';
import 'package:urbantrack/data/services/network_status_service.dart';

import '../../support/memory_activity_local_store.dart';

void main() {
  test('creates a local customer offline and exposes its detail', () async {
    final local = _MemoryCustomerLocalStore();
    final repository = OfflineFirstCustomerRepository(
      _RecordingRemoteCustomerRepository(),
      local,
      _MutableNetworkStatusService(false),
      now: () => DateTime.utc(2026, 8, 7, 16),
    );

    final result = await repository.createCustomer(_input, 'request-1');
    final detail = await repository.getCustomer(result.id!);
    final page = await repository.getCustomers();

    expect(result.id, 'local:request-1');
    expect(detail.name, 'Ferretería Central');
    expect(detail.status, 'Pendiente de sincronización');
    expect(page.customers.single.externalId, 'local:request-1');
    expect(await repository.pendingCount(), 1);
  });

  test('syncs the queued create with the original request id', () async {
    final local = _MemoryCustomerLocalStore();
    final remote = _RecordingRemoteCustomerRepository();
    final network = _MutableNetworkStatusService(false);
    final repository = OfflineFirstCustomerRepository(
      remote,
      local,
      network,
      now: () => DateTime.utc(2026, 8, 7, 16),
    );

    await repository.createCustomer(_input, 'stable-request-id');
    network.connected = true;
    await repository.syncPending();

    expect(remote.createRequestIds, ['stable-request-id']);
    expect(await repository.pendingCount(), 0);
    expect(
      await local.serverIdForLocalId('local:stable-request-id'),
      'server-customer-1',
    );
  });

  test('queues an ambiguous transient create failure', () async {
    final local = _MemoryCustomerLocalStore();
    final repository = OfflineFirstCustomerRepository(
      _RecordingRemoteCustomerRepository(
        createError: const ApiException(
          statusCode: 503,
          message: 'Servicio no disponible.',
        ),
      ),
      local,
      _MutableNetworkStatusService(true),
      now: () => DateTime.utc(2026, 8, 7, 16),
    );

    final result = await repository.createCustomer(
      _input,
      'ambiguous-request-id',
    );

    expect(result.id, 'local:ambiguous-request-id');
    expect(local.operations.single.requestId, 'ambiguous-request-id');
  });

  test('does not queue a validation failure', () async {
    final local = _MemoryCustomerLocalStore();
    final repository = OfflineFirstCustomerRepository(
      _RecordingRemoteCustomerRepository(
        createError: const ApiException(
          statusCode: 400,
          message: 'Datos inválidos.',
        ),
      ),
      local,
      _MutableNetworkStatusService(true),
    );

    expect(
      () => repository.createCustomer(_input, 'invalid-request'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.statusCode,
          'statusCode',
          400,
        ),
      ),
    );
    expect(await repository.pendingCount(), 0);
  });

  test('protects activity on a customer that is still local', () async {
    final repository = OfflineFirstCustomerRepository(
      _RecordingRemoteCustomerRepository(),
      _MemoryCustomerLocalStore(),
      _MutableNetworkStatusService(false),
      now: () => DateTime.utc(2026, 8, 7, 16),
    );
    final created = await repository.createCustomer(_input, 'request-activity');

    expect(
      () => repository.addNote(created.id!, 'Nota local', 'note-request-id'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          contains('Sincroniza el cliente'),
        ),
      ),
    );
  });

  test('queues and displays customer notes and reminders offline', () async {
    final activityLocal = MemoryActivityLocalStore();
    final repository = OfflineFirstCustomerRepository(
      _RecordingRemoteCustomerRepository(),
      _MemoryCustomerLocalStore(),
      _MutableNetworkStatusService(false),
      activityLocalStore: activityLocal,
      now: () => DateTime.utc(2026, 8, 18, 15),
    );
    final created = await repository.createCustomer(_input, 'customer-create');

    final note = await repository.addNote(
      created.id!,
      '  Nota sin conexión  ',
      'customer-note',
    );
    final reminder = await repository.addReminder(
      created.id!,
      text: '  Llamar mañana  ',
      reminderAtUtc: DateTime.utc(2026, 8, 19, 13),
      clientRequestId: 'customer-reminder',
      assignedToId: 'seller-id',
    );
    final detail = await repository.getCustomer(created.id!);

    expect(note.id, 'local:customer-note');
    expect(reminder.id, 'local:customer-reminder');
    expect(activityLocal.operations.map((item) => item.requestId), [
      'customer-note',
      'customer-reminder',
    ]);
    expect(detail.notes.single.text, 'Nota sin conexión');
    expect(detail.notes.single.createdAtUtc, DateTime.utc(2026, 8, 18, 15));
    expect(detail.reminders.single.text, 'Llamar mañana');
    expect(
      detail.reminders.single.reminderAtUtc,
      DateTime.utc(2026, 8, 19, 13),
    );
  });
}

const _input = CustomerInput(
  name: 'Ferretería Central',
  companyName: 'Central SAC',
  phone: '+51 999 111 222',
  email: 'ventas@example.test',
  address: 'Av. Principal 123',
  latitude: -12.0464,
  longitude: -77.0428,
);

class _MutableNetworkStatusService implements NetworkStatusService {
  _MutableNetworkStatusService(this.connected);

  bool connected;

  @override
  Future<bool> get isConnected async => connected;

  @override
  Stream<bool> get changes => const Stream.empty();
}

class _RecordingRemoteCustomerRepository implements CustomerRepository {
  _RecordingRemoteCustomerRepository({this.createError});

  final ApiException? createError;
  final List<String> createRequestIds = [];

  @override
  Future<ResourceCreationResult> addNote(
    String externalId,
    String text,
    String clientRequestId,
  ) async => const ResourceCreationResult(id: 'note-id', message: 'Created');

  @override
  Future<ResourceCreationResult> addReminder(
    String externalId, {
    required String text,
    required DateTime reminderAtUtc,
    required String clientRequestId,
    String? assignedToId,
  }) async =>
      const ResourceCreationResult(id: 'reminder-id', message: 'Created');

  @override
  Future<void> completeReminder(
    String customerExternalId,
    String reminderExternalId,
    String clientRequestId,
  ) async {}

  @override
  Future<ResourceCreationResult> createCustomer(
    CustomerInput input,
    String clientRequestId,
  ) async {
    createRequestIds.add(clientRequestId);
    final error = createError;
    if (error != null) throw error;
    return const ResourceCreationResult(
      id: 'server-customer-1',
      message: 'Creado',
    );
  }

  @override
  Future<CustomerPage> getCustomers({
    String? status,
    String? externalUserId,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async => CustomerPage(
    customers: const [],
    page: page,
    pageSize: pageSize,
    totalItems: 0,
    totalPages: 0,
  );

  @override
  Future<List<CustomerStatus>> getStatuses() async => const [];

  @override
  Future<CustomerDetail> getCustomer(String externalId) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateCustomer(String externalId, CustomerInput input) async {}

  @override
  Future<void> changeStatus(String externalId, int statusId) async {}
}

class _MemoryCustomerLocalStore implements CustomerLocalStore {
  final Map<String, CustomerSummary> summaries = {};
  final Map<String, CustomerDetail> details = {};
  final List<PendingCustomerOperation> operations = [];
  final Map<String, String> mappings = {};
  List<CustomerStatus> statuses = [];

  @override
  Future<void> cacheCustomers(List<CustomerSummary> customers) async {
    for (final customer in customers) {
      summaries[customer.externalId] = customer;
    }
  }

  @override
  Future<void> cacheDetail(CustomerDetail customer) async {
    details[customer.externalId] = customer;
  }

  @override
  Future<void> cacheStatuses(List<CustomerStatus> statuses) async {
    this.statuses = List.of(statuses);
  }

  @override
  Future<void> enqueueCreate(
    PendingCustomerOperation operation, {
    required CustomerSummary summary,
    required CustomerDetail detail,
  }) async {
    if (!operations.any((item) => item.requestId == operation.requestId)) {
      operations.add(operation);
    }
    summaries[summary.externalId] = summary;
    details[detail.externalId] = detail;
  }

  @override
  Future<void> markCreateSynced(
    String requestId, {
    required String localCustomerId,
    required String serverCustomerId,
  }) async {
    mappings[localCustomerId] = serverCustomerId;
    operations.removeWhere((item) => item.requestId == requestId);
    summaries.remove(localCustomerId);
    details.remove(localCustomerId);
  }

  @override
  Future<int> pendingCount() async => operations.length;

  @override
  Future<CustomerDetail?> readDetail(String externalId) async =>
      details[externalId];

  @override
  Future<List<PendingCustomerOperation>> readPending() async =>
      List.unmodifiable(operations);

  @override
  Future<List<CustomerSummary>> readPendingCustomers() async => summaries.values
      .where((customer) => customer.externalId.startsWith('local:'))
      .toList(growable: false);

  @override
  Future<List<CustomerStatus>> readStatuses() async =>
      List.unmodifiable(statuses);

  @override
  Future<CustomerPage> readCustomers({
    String? status,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async {
    final customers = summaries.values.toList(growable: false);
    return CustomerPage(
      customers: customers,
      page: page,
      pageSize: pageSize,
      totalItems: customers.length,
      totalPages: customers.isEmpty ? 0 : 1,
    );
  }

  @override
  Future<void> recordFailure(String requestId, String message) async {}

  @override
  Future<String?> serverIdForLocalId(String localCustomerId) async =>
      mappings[localCustomerId];
}
