import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urbantrack/app/urbantrack_app.dart';
import 'package:urbantrack/config/app_environment.dart';
import 'package:urbantrack/ui/core/branding/urbantrack_brand.dart';

import 'signed_in_auth_repository.dart';
import 'workday_test_doubles.dart';

Future<void> runWorkdayLifecycleFlow(WidgetTester tester) async {
  final workdays = StatefulWorkdayRepository();

  await tester.pumpWidget(
    UrbanTrackApp(
      brand: UrbanTrackBrand.config,
      environment: const AppEnvironment(apiBaseUrl: 'https://example.test'),
      authRepository: SignedInAuthRepository(),
      workdayRepository: workdays,
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

  final startButton = find.byKey(const ValueKey('start-workday-button'));
  expect(startButton, findsOneWidget);

  await tester.tap(startButton);
  await tester.pumpAndSettle();

  expect(workdays.startCalls, 1);
  expect(workdays.startedAtUtc?.isUtc, isTrue);
  expect(workdays.startLocation?.latitude, -12.0464);
  expect(workdays.startRequestId, isNotEmpty);
  expect(find.text('Tu jornada está activa.'), findsOneWidget);

  await tester.tap(find.byKey(const ValueKey('finish-workday-button')));
  await tester.pumpAndSettle();

  expect(find.text('GPS verificado'), findsOneWidget);
  final closeButton = find.byKey(const ValueKey('close-workday-button'));
  expect(closeButton, findsOneWidget);

  await tester.tap(closeButton);
  await tester.pumpAndSettle();

  expect(workdays.closeCalls, 1);
  expect(workdays.endedAtUtc?.isUtc, isTrue);
  expect(workdays.closeLocation?.longitude, -77.0428);
  expect(workdays.closeRequestId, isNotEmpty);
  expect(workdays.closeRequestId, isNot(workdays.startRequestId));
  expect(find.byKey(const ValueKey('start-workday-button')), findsOneWidget);
}
