import 'package:urbantrack/data/models/common/resource_creation_result.dart';
import 'package:urbantrack/data/models/common/user_reference.dart';
import 'package:urbantrack/data/models/customer/customer_detail.dart';
import 'package:urbantrack/data/models/customer/customer_input.dart';
import 'package:urbantrack/data/models/customer/customer_note.dart';
import 'package:urbantrack/data/models/customer/customer_page.dart';
import 'package:urbantrack/data/models/customer/customer_reminder.dart';
import 'package:urbantrack/data/models/customer/customer_status.dart';
import 'package:urbantrack/data/models/customer/customer_summary.dart';
import 'package:urbantrack/data/repositories/customer_repository.dart';

class StatefulCustomerRepository implements CustomerRepository {
  StatefulCustomerRepository({DateTime Function()? now})
    : _now = now ?? DateTime.now;

  static const statuses = [
    CustomerStatus(value: 1, label: 'Prospecto'),
    CustomerStatus(value: 2, label: 'Contactado'),
  ];

  final DateTime Function() _now;
  CustomerDetail? customer;
  CustomerInput? createdInput;
  CustomerInput? updatedInput;
  String? createRequestId;
  int createCalls = 0;
  int updateCalls = 0;
  int statusCalls = 0;
  int noteCalls = 0;
  int reminderCalls = 0;
  int completeReminderCalls = 0;

  @override
  Future<CustomerPage> getCustomers({
    String? status,
    String? externalUserId,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async {
    final current = customer;
    final normalizedSearch = search?.trim().toLowerCase() ?? '';
    final matchesStatus =
        status == null || status.isEmpty || current?.status == status;
    final matchesSearch =
        normalizedSearch.isEmpty ||
        [
          current?.name ?? '',
          current?.companyName ?? '',
          current?.phone ?? '',
          current?.email ?? '',
        ].any((value) => value.toLowerCase().contains(normalizedSearch));
    final customers = current != null && matchesStatus && matchesSearch
        ? [_summary(current)]
        : <CustomerSummary>[];
    return CustomerPage(
      customers: customers,
      page: page,
      pageSize: pageSize,
      totalItems: customers.length,
      totalPages: customers.isEmpty ? 0 : 1,
    );
  }

  @override
  Future<CustomerDetail> getCustomer(String externalId) async {
    final current = customer;
    if (current == null || current.externalId != externalId) {
      throw StateError('Customer $externalId does not exist.');
    }
    return current;
  }

  @override
  Future<List<CustomerStatus>> getStatuses() async => statuses;

  @override
  Future<ResourceCreationResult> createCustomer(
    CustomerInput input,
    String clientRequestId,
  ) async {
    createCalls += 1;
    createdInput = input;
    createRequestId = clientRequestId;
    customer = _fromInput(
      input,
      externalId: 'customer-integration-id',
      status: statuses.first,
    );
    return const ResourceCreationResult(
      id: 'customer-integration-id',
      message: 'Created',
    );
  }

  @override
  Future<void> updateCustomer(String externalId, CustomerInput input) async {
    final current = await getCustomer(externalId);
    updateCalls += 1;
    updatedInput = input;
    customer = _fromInput(
      input,
      externalId: externalId,
      status: statuses.firstWhere((status) => status.value == current.statusId),
      notes: current.notes,
      reminders: current.reminders,
    );
  }

  @override
  Future<void> changeStatus(String externalId, int statusId) async {
    final current = await getCustomer(externalId);
    final status = statuses.firstWhere((item) => item.value == statusId);
    statusCalls += 1;
    customer = _copy(current, statusId: status.value, status: status.label);
  }

  @override
  Future<ResourceCreationResult> addNote(
    String externalId,
    String text,
    String clientRequestId,
  ) async {
    final current = await getCustomer(externalId);
    noteCalls += 1;
    final note = CustomerNote(
      id: noteCalls,
      externalId: 'note-$noteCalls',
      text: text,
      author: _seller,
      createdAtUtc: _now().toUtc(),
    );
    customer = _copy(current, notes: [...current.notes, note]);
    return ResourceCreationResult(id: note.externalId, message: 'Created');
  }

  @override
  Future<ResourceCreationResult> addReminder(
    String externalId, {
    required String text,
    required DateTime reminderAtUtc,
    String? assignedToId,
  }) async {
    final current = await getCustomer(externalId);
    reminderCalls += 1;
    final reminder = CustomerReminder(
      id: reminderCalls,
      externalId: 'reminder-$reminderCalls',
      text: text,
      reminderAtUtc: reminderAtUtc.toUtc(),
      assignedTo: _seller,
      completed: false,
    );
    customer = _copy(current, reminders: [...current.reminders, reminder]);
    return ResourceCreationResult(id: reminder.externalId, message: 'Created');
  }

  @override
  Future<void> completeReminder(
    String customerExternalId,
    String reminderExternalId,
  ) async {
    final current = await getCustomer(customerExternalId);
    completeReminderCalls += 1;
    customer = _copy(
      current,
      reminders: current.reminders
          .map(
            (reminder) => reminder.externalId == reminderExternalId
                ? CustomerReminder(
                    id: reminder.id,
                    externalId: reminder.externalId,
                    text: reminder.text,
                    reminderAtUtc: reminder.reminderAtUtc,
                    assignedTo: reminder.assignedTo,
                    completed: true,
                  )
                : reminder,
          )
          .toList(growable: false),
    );
  }

  CustomerDetail _fromInput(
    CustomerInput input, {
    required String externalId,
    required CustomerStatus status,
    List<CustomerNote> notes = const [],
    List<CustomerReminder> reminders = const [],
  }) => CustomerDetail(
    id: 1,
    externalId: externalId,
    name: input.name.trim(),
    companyName: input.companyName.trim(),
    phone: input.phone.trim(),
    email: input.email.trim(),
    statusId: status.value,
    status: status.label,
    address: input.address.trim(),
    latitude: input.latitude,
    longitude: input.longitude,
    createdAtUtc: _now().toUtc(),
    seller: _seller,
    notes: notes,
    reminders: reminders,
  );
}

CustomerSummary _summary(CustomerDetail customer) => CustomerSummary(
  id: customer.id,
  externalId: customer.externalId,
  name: customer.name,
  companyName: customer.companyName,
  phone: customer.phone,
  email: customer.email,
  status: customer.status,
  createdAtUtc: customer.createdAtUtc,
  seller: customer.seller,
);

CustomerDetail _copy(
  CustomerDetail customer, {
  int? statusId,
  String? status,
  List<CustomerNote>? notes,
  List<CustomerReminder>? reminders,
}) => CustomerDetail(
  id: customer.id,
  externalId: customer.externalId,
  name: customer.name,
  companyName: customer.companyName,
  phone: customer.phone,
  email: customer.email,
  statusId: statusId ?? customer.statusId,
  status: status ?? customer.status,
  address: customer.address,
  latitude: customer.latitude,
  longitude: customer.longitude,
  createdAtUtc: customer.createdAtUtc,
  seller: customer.seller,
  notes: notes ?? customer.notes,
  reminders: reminders ?? customer.reminders,
);

const _seller = UserReference(
  externalId: 'seller-test-id',
  name: 'Vendedor de prueba',
);
