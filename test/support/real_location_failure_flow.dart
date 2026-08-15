import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urbantrack/app/urbantrack_app.dart';
import 'package:urbantrack/config/app_environment.dart';
import 'package:urbantrack/data/services/geolocator_location_service.dart';
import 'package:urbantrack/ui/core/branding/urbantrack_brand.dart';

import 'signed_in_auth_repository.dart';
import 'workday_test_doubles.dart';

Future<void> runLocationServicesDisabledFlow(WidgetTester tester) =>
    _runLocationFailureFlow(
      tester,
      expectedMessage: 'Activa la ubicación del dispositivo para continuar.',
    );

Future<void> runLocationPermissionDeniedFlow(WidgetTester tester) =>
    _runLocationFailureFlow(
      tester,
      expectedMessage:
          'Necesitamos permiso de ubicación para registrar la jornada.',
    );

Future<void> _runLocationFailureFlow(
  WidgetTester tester, {
  required String expectedMessage,
}) async {
  final workdays = StatefulWorkdayRepository();

  await tester.pumpWidget(
    UrbanTrackApp(
      brand: UrbanTrackBrand.config,
      environment: const AppEnvironment(apiBaseUrl: 'https://example.test'),
      authRepository: SignedInAuthRepository(),
      workdayRepository: workdays,
      locationService: const GeolocatorLocationService(),
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

  final startButton = find.byKey(const ValueKey('start-workday-button'));
  expect(startButton, findsOneWidget);
  await tester.tap(startButton);
  await tester.pumpAndSettle();

  expect(workdays.startCalls, 0);
  expect(find.text(expectedMessage), findsOneWidget);
  expect(startButton, findsOneWidget);
}
