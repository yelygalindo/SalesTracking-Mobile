import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urbantrack/app/urbantrack_app.dart';
import 'package:urbantrack/config/app_environment.dart';
import 'package:urbantrack/data/models/customer/customer_page.dart';
import 'package:urbantrack/data/models/customer/customer_summary.dart';
import 'package:urbantrack/data/models/workday/workday.dart';
import 'package:urbantrack/ui/core/branding/urbantrack_brand.dart';

import 'signed_in_auth_repository.dart';
import 'stateful_project_repository.dart';
import 'stateful_visit_repository.dart';
import 'workday_test_doubles.dart';

Future<void> runProjectLifecycleFlow(WidgetTester tester) async {
  final projects = StatefulProjectRepository(
    now: () => DateTime.utc(2026, 8, 15, 15),
  );
  final visits = StatefulVisitRepository();
  final workdays = StatefulWorkdayRepository()
    ..current = Workday(
      externalId: 'workday-project-lifecycle-id',
      status: 'open',
      startedAtUtc: DateTime.utc(2026, 8, 15, 14),
      startedReceivedAtUtc: DateTime.utc(2026, 8, 15, 14, 0, 2),
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
      customerRepository: _ProjectCustomerRepository(),
      projectRepository: projects,
      visitRepository: visits,
      attachmentRepository: EmptyAttachmentRepository(),
      historyRepository: EmptyHistoryRepository(),
    ),
  );
  await _pumpUi(tester);

  await tester.tap(find.byKey(const ValueKey('primary-nav-projects')));
  await _pumpUi(tester);
  expect(find.text('No hay obras para mostrar.'), findsOneWidget);

  await tester.tap(find.byKey(const ValueKey('new-project-button')));
  await _pumpUi(tester);
  expect(find.text('Registrar obra'), findsOneWidget);

  final saveProject = find.byKey(const ValueKey('save-project-button'));
  await tester.ensureVisible(saveProject);
  await tester.tap(saveProject);
  await _pumpUi(tester);
  expect(find.text('Ingresa el nombre de la obra.'), findsOneWidget);
  expect(find.text('Selecciona un cliente.'), findsOneWidget);
  expect(projects.createCalls, 0);

  await tester.enterText(
    find.byKey(const ValueKey('project-name-field')),
    'Torre Integración',
  );
  await tester.enterText(
    find.byKey(const ValueKey('project-description-field')),
    'Construcción residencial de prueba',
  );
  final customerDropdown = find.byKey(
    const ValueKey('project-customer-dropdown'),
  );
  await tester.ensureVisible(customerDropdown);
  await _pumpUi(tester);
  await tester.tap(
    find.descendant(
      of: customerDropdown,
      matching: find.byType(DropdownButtonFormField<String>),
    ),
  );
  await _pumpUi(tester);
  await tester.tap(find.text('Constructora Integración').last);
  await _pumpUi(tester);
  await tester.enterText(
    find.byKey(const ValueKey('project-amount-field')),
    '185000',
  );
  await tester.enterText(
    find.byKey(const ValueKey('project-progress-field')),
    '35',
  );
  await tester.enterText(
    find.byKey(const ValueKey('project-address-field')),
    'Av. Integración 456',
  );

  final captureLocation = find.byKey(
    const ValueKey('capture-project-location-button'),
  );
  await tester.ensureVisible(captureLocation);
  await tester.tap(captureLocation);
  await _pumpUi(tester);
  expect(find.text('-12.04640, -77.04280'), findsOneWidget);

  await tester.ensureVisible(saveProject);
  await tester.tap(saveProject);
  await _pumpUi(tester);

  expect(projects.createCalls, 1);
  expect(projects.createRequestId, isNotEmpty);
  expect(projects.createdInput?.customerExternalId, 'customer-test-id');
  expect(projects.createdInput?.latitude, -12.0464);
  expect(projects.createdInput?.longitude, -77.0428);
  expect(find.text('Torre Integración'), findsOneWidget);
  expect(find.text('Avance 35%'), findsOneWidget);

  final projectCard = find.byKey(
    const ValueKey('project-card-project-integration-id'),
  );
  await tester.tap(projectCard);
  await _pumpUi(tester);
  expect(find.text('Detalle de obra'), findsOneWidget);

  final editProject = find.byKey(const ValueKey('edit-project-button'));
  await tester.ensureVisible(editProject);
  await tester.tap(editProject);
  await _pumpUi(tester);
  expect(find.text('Actualizar obra'), findsWidgets);
  await tester.enterText(
    find.byKey(const ValueKey('project-name-field')),
    'Torre Integración Norte',
  );
  await tester.enterText(
    find.byKey(const ValueKey('project-progress-field')),
    '55',
  );
  await tester.ensureVisible(saveProject);
  await tester.tap(saveProject);
  await _pumpUi(tester);

  expect(projects.updateCalls, 1);
  expect(projects.updatedInput?.name, 'Torre Integración Norte');
  expect(projects.updatedInput?.progressPercentage, 55);
  expect(find.text('Torre Integración Norte'), findsWidgets);
  expect(find.text('55%'), findsOneWidget);

  final changeStatus = find.byKey(
    const ValueKey('change-project-status-button'),
  );
  await tester.ensureVisible(changeStatus);
  await tester.tap(changeStatus);
  await _pumpUi(tester);
  await tester.tap(find.byKey(const ValueKey('project-status-2')));
  await _pumpUi(tester);
  expect(projects.statusCalls, 1);
  expect(projects.project?.status, 'En progreso');
  await tester.pump(const Duration(seconds: 4));

  final addNote = find.byKey(const ValueKey('add-project-note-button'));
  await tester.ensureVisible(addNote);
  await tester.drag(find.byType(ListView), const Offset(0, -160));
  await _pumpUi(tester);
  await tester.tap(addNote);
  await _pumpUi(tester);
  await tester.enterText(
    find.byKey(const ValueKey('project-note-field')),
    'Materiales confirmados para el segundo piso',
  );
  await tester.tap(find.byKey(const ValueKey('save-project-note-button')));
  await _pumpUi(tester);

  expect(projects.noteCalls, 1);
  expect(projects.noteRequestId, isNotEmpty);
  expect(projects.noteOccurredAtUtc?.isUtc, isTrue);
  expect(
    find.text('Materiales confirmados para el segundo piso'),
    findsWidgets,
  );
  expect(find.text('Obra creada'), findsOneWidget);
  expect(find.text('Obra actualizada'), findsOneWidget);
  expect(find.text('Estado actualizado'), findsOneWidget);
  expect(find.text('Nota agregada'), findsOneWidget);

  final startVisit = find.byKey(const ValueKey('start-visit-button'));
  await tester.fling(find.byType(ListView), const Offset(0, 1200), 1200);
  await _pumpUi(tester);
  await tester.tap(startVisit);
  await _pumpUi(tester);
  await tester.enterText(
    find.byKey(const ValueKey('visit-check-in-note')),
    'Verificar avance estructural',
  );
  await tester.tap(find.byKey(const ValueKey('confirm-visit-check-in')));
  await _pumpUi(tester);

  expect(visits.checkInCalls, 1);
  expect(visits.current?.targetExternalId, 'project-integration-id');
  expect(visits.checkInNote, 'Verificar avance estructural');
  expect(visits.checkInLocation?.latitude, -12.0464);

  final finishVisit = find.byKey(const ValueKey('finish-visit-button'));
  await tester.ensureVisible(finishVisit);
  await tester.tap(finishVisit);
  await _pumpUi(tester);
  await tester.enterText(
    find.byKey(const ValueKey('visit-check-out-result')),
    'Avance verificado',
  );
  await tester.enterText(
    find.byKey(const ValueKey('visit-check-out-note')),
    'La estructura coincide con el cronograma',
  );
  await tester.tap(find.byKey(const ValueKey('confirm-visit-check-out')));
  await _pumpUi(tester);

  expect(visits.checkOutCalls, 1);
  expect(visits.result, 'Avance verificado');
  expect(visits.checkOutNote, 'La estructura coincide con el cronograma');
  expect(visits.checkOutLocation?.longitude, -77.0428);
  expect(visits.current, isNull);
  expect(find.byKey(const ValueKey('start-visit-button')), findsOneWidget);
}

Future<void> _pumpUi(WidgetTester tester) async {
  await tester.pump();
  for (var frame = 0; frame < 6; frame += 1) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

class _ProjectCustomerRepository extends EmptyCustomerRepository {
  @override
  Future<CustomerPage> getCustomers({
    String? status,
    String? externalUserId,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async => CustomerPage(
    customers: const [_customer],
    page: page,
    pageSize: pageSize,
    totalItems: 1,
    totalPages: 1,
  );
}

const _customer = CustomerSummary(
  id: 1,
  externalId: 'customer-test-id',
  name: 'Cliente Integración',
  companyName: 'Constructora Integración',
  phone: '70000000',
  email: 'cliente@example.test',
  status: 'Activo',
  createdAtUtc: null,
  seller: null,
);
