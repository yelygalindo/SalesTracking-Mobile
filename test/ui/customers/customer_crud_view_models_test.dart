import 'package:flutter_test/flutter_test.dart';
import 'package:urbantrack/data/models/common/location_sample.dart';
import 'package:urbantrack/data/models/common/resource_creation_result.dart';
import 'package:urbantrack/data/models/common/user_reference.dart';
import 'package:urbantrack/data/models/customer/customer_detail.dart';
import 'package:urbantrack/data/models/customer/customer_input.dart';
import 'package:urbantrack/data/models/customer/customer_page.dart';
import 'package:urbantrack/data/models/customer/customer_status.dart';
import 'package:urbantrack/data/repositories/customer_repository.dart';
import 'package:urbantrack/data/services/location_service.dart';
import 'package:urbantrack/ui/customers/customer_detail_view_model.dart';
import 'package:urbantrack/ui/customers/customer_form_view_model.dart';

void main() {
  test('creates a customer with stable request id and captured GPS', () async {
    final repository = _CrudCustomerRepository();
    final viewModel = CustomerFormViewModel(
      repository,
      _FixedLocationService(),
      requestId: () => 'request-id',
    );

    await viewModel.initialize();
    expect(await viewModel.captureLocation(), isTrue);
    expect(
      await viewModel.save(
        name: 'Ricardo',
        companyName: 'Horizonte',
        phone: '70010001',
        email: 'seller@example.test',
        address: 'Av. Banzer',
      ),
      isTrue,
    );

    expect(repository.createdRequestId, 'request-id');
    expect(repository.createdInput?.latitude, -17.75);
    expect(viewModel.savedExternalId, 'customer-id');
  });

  test('updates a customer with the loaded concurrency timestamp', () async {
    final repository = _CrudCustomerRepository();
    final viewModel = CustomerFormViewModel(
      repository,
      _FixedLocationService(),
      externalId: 'customer-id',
    );
    await viewModel.initialize();

    expect(
      await viewModel.save(
        name: 'Ricardo',
        companyName: 'Horizonte actualizado',
        phone: '70010001',
        email: '',
        address: 'Av. Banzer',
      ),
      isTrue,
    );

    expect(
      repository.updatedInput?.expectedUpdatedAtUtc,
      DateTime.utc(2026, 8, 18, 14, 30),
    );
    expect(repository.updatedInput?.email, isEmpty);
  });

  test('loads detail and refreshes after changing commercial status', () async {
    final repository = _CrudCustomerRepository();
    final viewModel = CustomerDetailViewModel(repository, 'customer-id');

    await viewModel.load();
    expect(viewModel.customer?.status, 'Prospecto');

    expect(
      await viewModel.changeStatus(
        const CustomerStatus(value: 2, label: 'Activo'),
      ),
      isTrue,
    );
    expect(repository.changedStatusId, 2);
    expect(viewModel.customer?.status, 'Activo');
  });

  test('adds notes, schedules reminders and completes them', () async {
    final repository = _CrudCustomerRepository();
    final viewModel = CustomerDetailViewModel(
      repository,
      'customer-id',
      requestId: () => 'note-request-id',
    );
    await viewModel.load();
    final reminderAt = DateTime.utc(2026, 8, 10, 14, 30);

    expect(await viewModel.addNote('Seguimiento realizado'), isTrue);
    expect(
      await viewModel.addReminder(
        text: 'Llamar al cliente',
        reminderAtUtc: reminderAt,
      ),
      isTrue,
    );
    expect(await viewModel.completeReminder('reminder-id'), isTrue);

    expect(repository.noteText, 'Seguimiento realizado');
    expect(repository.noteRequestId, 'note-request-id');
    expect(repository.reminderAtUtc, reminderAt);
    expect(repository.completedReminderId, 'reminder-id');
  });
}

class _CrudCustomerRepository implements CustomerRepository {
  CustomerInput? createdInput;
  CustomerInput? updatedInput;
  String? createdRequestId;
  int currentStatusId = 1;
  int? changedStatusId;
  String? noteText;
  String? noteRequestId;
  DateTime? reminderAtUtc;
  String? completedReminderId;

  @override
  Future<ResourceCreationResult> addNote(
    String externalId,
    String text,
    String clientRequestId,
  ) async {
    noteText = text;
    noteRequestId = clientRequestId;
    return const ResourceCreationResult(id: 'note-id', message: 'Created');
  }

  @override
  Future<ResourceCreationResult> addReminder(
    String externalId, {
    required String text,
    required DateTime reminderAtUtc,
    required String clientRequestId,
    String? assignedToId,
  }) async {
    this.reminderAtUtc = reminderAtUtc;
    return const ResourceCreationResult(id: 'reminder-id', message: 'Created');
  }

  @override
  Future<void> completeReminder(
    String customerExternalId,
    String reminderExternalId,
    String clientRequestId,
  ) async {
    completedReminderId = reminderExternalId;
  }

  @override
  Future<void> changeStatus(String externalId, int statusId) async {
    changedStatusId = statusId;
    currentStatusId = statusId;
  }

  @override
  Future<ResourceCreationResult> createCustomer(
    CustomerInput input,
    String clientRequestId,
  ) async {
    createdInput = input;
    createdRequestId = clientRequestId;
    return const ResourceCreationResult(id: 'customer-id', message: 'Created');
  }

  @override
  Future<CustomerDetail> getCustomer(String externalId) async =>
      _customerDetail(currentStatusId);

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
  Future<List<CustomerStatus>> getStatuses() async => const [
    CustomerStatus(value: 1, label: 'Prospecto'),
    CustomerStatus(value: 2, label: 'Activo'),
  ];

  @override
  Future<void> updateCustomer(String externalId, CustomerInput input) async {
    updatedInput = input;
  }
}

class _FixedLocationService implements LocationService {
  @override
  Future<LocationSample> captureCurrent() async => const LocationSample(
    latitude: -17.75,
    longitude: -63.18,
    accuracyMeters: 6,
  );
}

CustomerDetail _customerDetail(int statusId) => CustomerDetail(
  id: 7,
  externalId: 'customer-id',
  name: 'Ricardo Alarcón',
  companyName: 'Constructora Horizonte',
  phone: '700 10001',
  email: 'seller@example.test',
  statusId: statusId,
  status: statusId == 1 ? 'Prospecto' : 'Activo',
  address: 'Av. Banzer',
  latitude: -17.75,
  longitude: -63.18,
  createdAtUtc: DateTime.utc(2026, 8, 7),
  updatedAtUtc: DateTime.utc(2026, 8, 18, 14, 30),
  seller: const UserReference(externalId: 'seller-id', name: 'Carlos Gómez'),
  notes: const [],
  reminders: const [],
);
