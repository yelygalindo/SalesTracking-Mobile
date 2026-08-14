import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urbantrack/app/urbantrack_app.dart';
import 'package:urbantrack/config/app_environment.dart';
import 'package:urbantrack/ui/core/branding/urbantrack_brand.dart';

import 'signed_in_auth_repository.dart';
import 'workday_test_doubles.dart';

Future<void> runAppNavigationFlow(WidgetTester tester) async {
  final authRepository = SignedInAuthRepository();

  await tester.pumpWidget(
    UrbanTrackApp(
      brand: UrbanTrackBrand.config,
      environment: const AppEnvironment(apiBaseUrl: 'https://example.test'),
      authRepository: authRepository,
      workdayRepository: InactiveWorkdayRepository(),
      locationService: FixedLocationService(),
      networkStatusService: DisconnectedNetworkStatusService(),
      syncRepository: EmptySyncRepository(),
      customerRepository: EmptyCustomerRepository(),
      projectRepository: EmptyProjectRepository(),
      visitRepository: EmptyVisitRepository(),
      attachmentRepository: EmptyAttachmentRepository(),
      historyRepository: EmptyHistoryRepository(),
    ),
  );
  await tester.pumpAndSettle();

  expect(find.text('UrbanTrackCRM'), findsOneWidget);
  expect(find.textContaining('Vendedor de prueba'), findsOneWidget);

  await tester.tap(find.byKey(const ValueKey('primary-nav-customers')));
  await tester.pumpAndSettle();
  expect(find.text('Buscar nombre, empresa, teléfono…'), findsOneWidget);

  await tester.tap(find.byKey(const ValueKey('primary-nav-projects')));
  await tester.pumpAndSettle();
  expect(find.text('Estado'), findsOneWidget);
  expect(find.text('Cliente'), findsOneWidget);

  await tester.tap(find.byKey(const ValueKey('primary-nav-history')));
  await tester.pumpAndSettle();
  expect(find.text('Todo lo que registraste'), findsOneWidget);

  await tester.tap(find.byKey(const ValueKey('primary-nav-home')));
  await tester.pumpAndSettle();
  expect(find.text('Iniciar jornada'), findsOneWidget);

  await tester.tap(find.byKey(const ValueKey('logout-button')));
  await tester.pumpAndSettle();

  expect(authRepository.logoutCalls, 1);
  expect(find.text('Bienvenido a UrbanTrackCRM'), findsOneWidget);
}
