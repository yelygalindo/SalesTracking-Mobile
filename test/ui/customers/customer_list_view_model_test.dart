import 'package:flutter_test/flutter_test.dart';
import 'package:urbantrack/data/models/common/user_reference.dart';
import 'package:urbantrack/data/models/common/resource_creation_result.dart';
import 'package:urbantrack/data/models/customer/customer_detail.dart';
import 'package:urbantrack/data/models/customer/customer_input.dart';
import 'package:urbantrack/data/models/customer/customer_page.dart';
import 'package:urbantrack/data/models/customer/customer_status.dart';
import 'package:urbantrack/data/models/customer/customer_summary.dart';
import 'package:urbantrack/data/repositories/customer_repository.dart';
import 'package:urbantrack/ui/customers/customer_list_view_model.dart';

void main() {
  test('loads statuses and appends the next customer page', () async {
    final repository = _RecordingCustomerRepository();
    final viewModel = CustomerListViewModel(repository, pageSize: 1);

    await viewModel.initialize();
    expect(viewModel.statuses.single.label, 'Activo');
    expect(viewModel.customers.single.name, 'Cliente 1');
    expect(viewModel.canLoadMore, isTrue);

    await viewModel.loadMore();
    expect(viewModel.customers.map((customer) => customer.name), [
      'Cliente 1',
      'Cliente 2',
    ]);
    expect(repository.pages, [1, 2]);
  });

  test(
    'sends selected status and debounced search to the repository',
    () async {
      final repository = _RecordingCustomerRepository();
      final viewModel = CustomerListViewModel(
        repository,
        searchDebounce: Duration.zero,
      );
      await viewModel.initialize();

      await viewModel.selectStatus(
        const CustomerStatus(value: 1, label: 'Activo'),
      );
      viewModel.updateSearch('Horizonte');
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(repository.statuses.last, 'Activo');
      expect(repository.searches.last, 'Horizonte');
      viewModel.dispose();
    },
  );
}

class _RecordingCustomerRepository implements CustomerRepository {
  final List<int> pages = [];
  final List<String?> statuses = [];
  final List<String?> searches = [];

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
    String? assignedToId,
  }) async =>
      const ResourceCreationResult(id: 'reminder-id', message: 'Created');

  @override
  Future<void> completeReminder(
    String customerExternalId,
    String reminderExternalId,
  ) async {}

  @override
  Future<void> changeStatus(String externalId, int statusId) async {}

  @override
  Future<ResourceCreationResult> createCustomer(
    CustomerInput input,
    String clientRequestId,
  ) async =>
      const ResourceCreationResult(id: 'customer-id', message: 'Created');

  @override
  Future<CustomerDetail> getCustomer(String externalId) {
    throw UnimplementedError();
  }

  @override
  Future<CustomerPage> getCustomers({
    String? status,
    String? externalUserId,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async {
    pages.add(page);
    statuses.add(status);
    searches.add(search);
    return CustomerPage(
      customers: [_customer(page)],
      page: page,
      pageSize: pageSize,
      totalItems: 2,
      totalPages: 2,
    );
  }

  @override
  Future<List<CustomerStatus>> getStatuses() async => const [
    CustomerStatus(value: 1, label: 'Activo'),
  ];

  @override
  Future<void> updateCustomer(String externalId, CustomerInput input) async {}
}

CustomerSummary _customer(int index) => CustomerSummary(
  id: index,
  externalId: 'customer-$index',
  name: 'Cliente $index',
  companyName: 'Empresa $index',
  phone: '700 1000$index',
  email: '',
  status: 'Activo',
  createdAtUtc: DateTime.utc(2026, 8, 7),
  seller: const UserReference(externalId: 'seller-id', name: 'Carlos'),
);
