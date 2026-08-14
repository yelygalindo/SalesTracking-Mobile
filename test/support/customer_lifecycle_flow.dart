import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urbantrack/app/urbantrack_app.dart';
import 'package:urbantrack/config/app_environment.dart';
import 'package:urbantrack/ui/core/branding/urbantrack_brand.dart';

import 'signed_in_auth_repository.dart';
import 'stateful_customer_repository.dart';
import 'workday_test_doubles.dart';

Future<void> runCustomerLifecycleFlow(WidgetTester tester) async {
  final customers = StatefulCustomerRepository(
    now: () => DateTime.utc(2026, 8, 14, 15),
  );

  await tester.pumpWidget(
    UrbanTrackApp(
      brand: UrbanTrackBrand.config,
      environment: const AppEnvironment(apiBaseUrl: 'https://example.test'),
      authRepository: SignedInAuthRepository(),
      workdayRepository: InactiveWorkdayRepository(),
      locationService: FixedLocationService(),
      networkStatusService: DisconnectedNetworkStatusService(),
      syncRepository: EmptySyncRepository(),
      customerRepository: customers,
      projectRepository: EmptyProjectRepository(),
      visitRepository: EmptyVisitRepository(),
      attachmentRepository: EmptyAttachmentRepository(),
      historyRepository: EmptyHistoryRepository(),
    ),
  );
  await _pumpUi(tester);

  await tester.tap(find.byKey(const ValueKey('primary-nav-customers')));
  await _pumpUi(tester);
  expect(find.text('No encontramos clientes'), findsOneWidget);

  await tester.tap(find.byKey(const ValueKey('new-customer-button')));
  await _pumpUi(tester);
  expect(find.text('Registrar cliente'), findsOneWidget);

  final saveCustomer = find.byKey(const ValueKey('save-customer-button'));
  await tester.ensureVisible(saveCustomer);
  await tester.tap(saveCustomer);
  await _pumpUi(tester);
  expect(find.text('Campo obligatorio.'), findsNWidgets(4));
  expect(customers.createCalls, 0);

  await tester.enterText(
    find.byKey(const ValueKey('customer-name-field')),
    'Ana Torres',
  );
  await tester.enterText(
    find.byKey(const ValueKey('customer-company-field')),
    'Constructora Norte',
  );
  await tester.enterText(
    find.byKey(const ValueKey('customer-phone-field')),
    '700 12345',
  );
  await tester.enterText(
    find.byKey(const ValueKey('customer-email-field')),
    'ana@example.test',
  );
  await tester.enterText(
    find.byKey(const ValueKey('customer-address-field')),
    'Av. Integración 123',
  );

  final captureLocation = find.byKey(
    const ValueKey('capture-customer-location-button'),
  );
  await tester.ensureVisible(captureLocation);
  await tester.tap(captureLocation);
  await _pumpUi(tester);
  expect(find.text('-12.04640, -77.04280'), findsOneWidget);

  await tester.ensureVisible(saveCustomer);
  await tester.tap(saveCustomer);
  await _pumpUi(tester);

  expect(customers.createCalls, 1);
  expect(customers.createRequestId, isNotEmpty);
  expect(customers.createdInput?.latitude, -12.0464);
  expect(customers.createdInput?.longitude, -77.0428);
  expect(find.text('Ana Torres'), findsOneWidget);
  expect(find.text('Constructora Norte'), findsOneWidget);

  final customerCard = find.byKey(
    const ValueKey('customer-card-customer-integration-id'),
  );
  await tester.tap(customerCard);
  await _pumpUi(tester);
  expect(find.text('Detalle de cliente'), findsOneWidget);

  final editCustomer = find.byKey(const ValueKey('edit-customer-button'));
  await tester.ensureVisible(editCustomer);
  await tester.tap(editCustomer);
  await _pumpUi(tester);
  expect(find.text('Actualizar cliente'), findsOneWidget);
  await tester.enterText(
    find.byKey(const ValueKey('customer-company-field')),
    'Constructora Norte Renovada',
  );
  await tester.ensureVisible(saveCustomer);
  await tester.tap(saveCustomer);
  await _pumpUi(tester);

  expect(customers.updateCalls, 1);
  expect(customers.updatedInput?.companyName, 'Constructora Norte Renovada');
  expect(find.text('Constructora Norte Renovada'), findsOneWidget);

  final statusDropdown = find.byKey(const ValueKey('customer-status-dropdown'));
  await tester.ensureVisible(statusDropdown);
  await tester.tap(statusDropdown);
  await _pumpUi(tester);
  await tester.tap(find.text('Contactado'));
  await _pumpUi(tester);
  expect(customers.statusCalls, 1);
  expect(customers.customer?.status, 'Contactado');

  final addNote = find.byKey(const ValueKey('add-customer-note-button'));
  await tester.ensureVisible(addNote);
  await tester.tap(addNote);
  await _pumpUi(tester);
  await tester.enterText(
    find.byKey(const ValueKey('customer-note-field')),
    'Solicitó una nueva cotización',
  );
  await tester.tap(find.text('Guardar nota'));
  await _pumpUi(tester);
  expect(customers.noteCalls, 1);
  expect(find.text('Solicitó una nueva cotización'), findsOneWidget);

  final addReminder = find.byKey(
    const ValueKey('add-customer-reminder-button'),
  );
  await tester.ensureVisible(addReminder);
  await tester.tap(addReminder);
  await _pumpUi(tester);
  await tester.enterText(
    find.byKey(const ValueKey('customer-reminder-field')),
    'Llamar para seguimiento',
  );
  await tester.tap(find.text('Elegir fecha'));
  await _pumpUi(tester);
  await tester.tap(_dialogConfirmation());
  await _pumpUi(tester);
  await tester.tap(_dialogConfirmation());
  await _pumpUi(tester);

  expect(customers.reminderCalls, 1);
  expect(find.text('Llamar para seguimiento'), findsOneWidget);

  final completeReminder = find.byKey(
    const ValueKey('complete-reminder-reminder-1'),
  );
  await tester.ensureVisible(completeReminder);
  await tester.tap(completeReminder);
  await _pumpUi(tester);
  expect(customers.completeReminderCalls, 1);
  expect(find.text('No hay recordatorios pendientes.'), findsOneWidget);
}

Finder _dialogConfirmation() {
  final ok = find.text('OK');
  return ok.evaluate().isNotEmpty ? ok : find.text('Aceptar');
}

Future<void> _pumpUi(WidgetTester tester) async {
  await tester.pump();
  for (var frame = 0; frame < 6; frame += 1) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
