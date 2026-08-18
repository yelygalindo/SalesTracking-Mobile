import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urbantrack/data/models/common/location_sample.dart';
import 'package:urbantrack/data/models/common/resource_creation_result.dart';
import 'package:urbantrack/data/models/common/user_reference.dart';
import 'package:urbantrack/data/models/customer/customer_detail.dart';
import 'package:urbantrack/data/models/customer/customer_input.dart';
import 'package:urbantrack/data/models/customer/customer_note.dart';
import 'package:urbantrack/data/models/customer/customer_page.dart';
import 'package:urbantrack/data/models/customer/customer_reminder.dart';
import 'package:urbantrack/data/models/customer/customer_status.dart';
import 'package:urbantrack/data/repositories/customer_repository.dart';
import 'package:urbantrack/data/services/location_service.dart';
import 'package:urbantrack/ui/core/branding/brand_scope.dart';
import 'package:urbantrack/ui/core/branding/urbantrack_brand.dart';
import 'package:urbantrack/ui/customers/customer_detail_screen.dart';
import 'package:urbantrack/ui/customers/customer_form_screen.dart';

import '../../support/workday_test_doubles.dart';

void main() {
  testWidgets('renders detail sections on a narrow screen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      BrandScope(
        brand: UrbanTrackBrand.config,
        child: MaterialApp(
          home: CustomerDetailScreen(
            repository: _ScreenCustomerRepository(),
            visitRepository: EmptyVisitRepository(),
            externalId: 'customer-id',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ricardo Alarcón'), findsOneWidget);
    expect(find.text('Llamar por cotización'), findsOneWidget);
    expect(find.text('Solicitó una cotización.'), findsOneWidget);
    expect(find.byTooltip('Nuevo recordatorio'), findsOneWidget);
    expect(find.byTooltip('Nueva nota'), findsOneWidget);
    expect(find.byTooltip('Marcar como completado'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('adapts the customer form to a tablet width', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1024, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: CustomerFormScreen(
          repository: _ScreenCustomerRepository(),
          locationService: _ScreenLocationService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Registrar cliente'), findsOneWidget);
    expect(find.text('Teléfono *'), findsOneWidget);
    expect(find.text('Correo (opcional)'), findsOneWidget);
    expect(find.text('Usar ubicación actual'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _ScreenCustomerRepository implements CustomerRepository {
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
  Future<void> changeStatus(String externalId, int statusId) async {}

  @override
  Future<ResourceCreationResult> createCustomer(
    CustomerInput input,
    String clientRequestId,
  ) async =>
      const ResourceCreationResult(id: 'customer-id', message: 'Created');

  @override
  Future<CustomerDetail> getCustomer(String externalId) async => _detail;

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
    CustomerStatus(value: 1, label: 'Activo'),
  ];

  @override
  Future<void> updateCustomer(String externalId, CustomerInput input) async {}
}

class _ScreenLocationService implements LocationService {
  @override
  Future<LocationSample> captureCurrent() async => const LocationSample(
    latitude: -17.75,
    longitude: -63.18,
    accuracyMeters: 6,
  );
}

final _detail = CustomerDetail(
  id: 7,
  externalId: 'customer-id',
  name: 'Ricardo Alarcón',
  companyName: 'Constructora Horizonte',
  phone: '700 10001',
  email: 'seller@example.test',
  statusId: 1,
  status: 'Activo',
  address: 'Av. Banzer',
  latitude: -17.75,
  longitude: -63.18,
  createdAtUtc: DateTime.utc(2026, 8, 7),
  seller: const UserReference(externalId: 'seller-id', name: 'Carlos Gómez'),
  notes: [
    CustomerNote(
      id: 1,
      externalId: 'note-id',
      text: 'Solicitó una cotización.',
      author: const UserReference(
        externalId: 'seller-id',
        name: 'Carlos Gómez',
      ),
      createdAtUtc: DateTime.utc(2026, 8, 7, 16),
    ),
  ],
  reminders: [
    CustomerReminder(
      id: 2,
      externalId: 'reminder-id',
      text: 'Llamar por cotización',
      reminderAtUtc: DateTime.utc(2026, 8, 8, 15),
      assignedTo: const UserReference(
        externalId: 'seller-id',
        name: 'Carlos Gómez',
      ),
      completed: false,
    ),
  ],
);
