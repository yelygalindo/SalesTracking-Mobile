import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urbantrack/app/urbantrack_app.dart';
import 'package:urbantrack/config/app_environment.dart';
import 'package:urbantrack/data/models/common/resource_creation_result.dart';
import 'package:urbantrack/data/models/common/user_reference.dart';
import 'package:urbantrack/data/models/customer/customer_detail.dart';
import 'package:urbantrack/data/models/customer/customer_input.dart';
import 'package:urbantrack/data/models/customer/customer_page.dart';
import 'package:urbantrack/data/models/customer/customer_status.dart';
import 'package:urbantrack/data/models/customer/customer_summary.dart';
import 'package:urbantrack/data/models/workday/workday.dart';
import 'package:urbantrack/data/repositories/customer_repository.dart';
import 'package:urbantrack/ui/core/branding/urbantrack_brand.dart';

import 'signed_in_auth_repository.dart';
import 'stateful_visit_repository.dart';
import 'workday_test_doubles.dart';

Future<void> runVisitLifecycleFlow(WidgetTester tester) async {
  final visits = StatefulVisitRepository();
  final workdays = StatefulWorkdayRepository()
    ..current = Workday(
      externalId: 'workday-test-id',
      status: 'open',
      startedAtUtc: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
      startedReceivedAtUtc: DateTime.now().toUtc(),
      startLatitude: -12.0464,
      startLongitude: -77.0428,
    );

  await tester.pumpWidget(
    UrbanTrackApp(
      brand: UrbanTrackBrand.config,
      environment: const AppEnvironment(apiBaseUrl: 'https://example.test'),
      authRepository: SignedInAuthRepository(),
      workdayRepository: workdays,
      locationService: FixedLocationService(),
      networkStatusService: DisconnectedNetworkStatusService(),
      syncRepository: EmptySyncRepository(),
      customerRepository: _VisitFlowCustomerRepository(),
      projectRepository: EmptyProjectRepository(),
      visitRepository: visits,
      attachmentRepository: EmptyAttachmentRepository(),
      historyRepository: EmptyHistoryRepository(),
    ),
  );
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const ValueKey('primary-nav-customers')));
  await tester.pumpAndSettle();

  final customerCard = find.byKey(
    const ValueKey('customer-card-customer-test-id'),
  );
  expect(customerCard, findsOneWidget);
  await tester.tap(customerCard);
  await tester.pumpAndSettle();

  final startButton = find.byKey(const ValueKey('start-visit-button'));
  await tester.ensureVisible(startButton);
  await tester.tap(startButton);
  await tester.pumpAndSettle();

  await tester.enterText(
    find.byKey(const ValueKey('visit-check-in-note')),
    'Presentar propuesta comercial',
  );
  await tester.tap(find.byKey(const ValueKey('confirm-visit-check-in')));
  await tester.pumpAndSettle();

  expect(visits.checkInCalls, 1);
  expect(visits.checkInAtUtc?.isUtc, isTrue);
  expect(visits.checkInLocation?.latitude, -12.0464);
  expect(visits.checkInRequestId, isNotEmpty);
  expect(visits.checkInNote, 'Presentar propuesta comercial');

  final finishButton = find.byKey(const ValueKey('finish-visit-button'));
  await tester.ensureVisible(finishButton);
  await tester.tap(finishButton);
  await tester.pumpAndSettle();

  final confirmCheckOut = find.byKey(const ValueKey('confirm-visit-check-out'));
  await tester.tap(confirmCheckOut);
  await tester.pumpAndSettle();
  expect(find.text('Registra el resultado de la visita.'), findsOneWidget);
  expect(visits.checkOutCalls, 0);

  await tester.enterText(
    find.byKey(const ValueKey('visit-check-out-result')),
    'Gestión realizada',
  );
  await tester.enterText(
    find.byKey(const ValueKey('visit-check-out-note')),
    'Cliente interesado en recibir una cotización',
  );
  await tester.tap(confirmCheckOut);
  await tester.pumpAndSettle();

  expect(visits.checkOutCalls, 1);
  expect(visits.checkOutAtUtc?.isUtc, isTrue);
  expect(visits.checkOutLocation?.longitude, -77.0428);
  expect(visits.checkOutRequestId, isNotEmpty);
  expect(visits.checkOutRequestId, isNot(visits.checkInRequestId));
  expect(visits.result, 'Gestión realizada');
  expect(visits.checkOutNote, 'Cliente interesado en recibir una cotización');
  expect(visits.current, isNull);
  expect(find.byKey(const ValueKey('start-visit-button')), findsOneWidget);
}

class _VisitFlowCustomerRepository implements CustomerRepository {
  @override
  Future<CustomerPage> getCustomers({
    String? status,
    String? externalUserId,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async => CustomerPage(
    customers: const [_customerSummary],
    page: page,
    pageSize: pageSize,
    totalItems: 1,
    totalPages: 1,
  );

  @override
  Future<CustomerDetail> getCustomer(String externalId) async =>
      _customerDetail;

  @override
  Future<List<CustomerStatus>> getStatuses() async => const [
    CustomerStatus(value: 1, label: 'Activo'),
  ];

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
      const ResourceCreationResult(id: 'customer-test-id', message: 'Created');

  @override
  Future<void> updateCustomer(String externalId, CustomerInput input) async {}
}

const _seller = UserReference(
  externalId: 'seller-test-id',
  name: 'Vendedor de prueba',
);

const _customerSummary = CustomerSummary(
  id: 1,
  externalId: 'customer-test-id',
  name: 'Cliente Integración',
  companyName: 'Constructora Demo',
  phone: '70000000',
  email: 'cliente@example.test',
  status: 'Activo',
  createdAtUtc: null,
  seller: _seller,
);

const _customerDetail = CustomerDetail(
  id: 1,
  externalId: 'customer-test-id',
  name: 'Cliente Integración',
  companyName: 'Constructora Demo',
  phone: '70000000',
  email: 'cliente@example.test',
  statusId: 1,
  status: 'Activo',
  address: 'Av. de prueba',
  latitude: -12.0464,
  longitude: -77.0428,
  createdAtUtc: null,
  seller: _seller,
  notes: [],
  reminders: [],
);
