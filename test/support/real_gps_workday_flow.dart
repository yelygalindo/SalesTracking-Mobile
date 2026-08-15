import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urbantrack/app/urbantrack_app.dart';
import 'package:urbantrack/config/app_environment.dart';
import 'package:urbantrack/data/models/common/location_sample.dart';
import 'package:urbantrack/data/services/geolocator_location_service.dart';
import 'package:urbantrack/ui/core/branding/urbantrack_brand.dart';

import 'signed_in_auth_repository.dart';
import 'workday_test_doubles.dart';

Future<void> runRealGpsWorkdayFlow(WidgetTester tester) async {
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

  expect(workdays.startCalls, 1);
  _expectValidPosition(workdays.startLocation);
  expect(find.text('Tu jornada está activa.'), findsOneWidget);

  await tester.tap(find.byKey(const ValueKey('finish-workday-button')));
  await tester.pumpAndSettle();

  expect(find.text('GPS verificado'), findsOneWidget);

  await tester.tap(find.byKey(const ValueKey('close-workday-button')));
  await tester.pumpAndSettle();

  expect(workdays.closeCalls, 1);
  _expectValidPosition(workdays.closeLocation);
  expect(workdays.startRequestId, isNotEmpty);
  expect(workdays.closeRequestId, isNotEmpty);
  expect(workdays.closeRequestId, isNot(workdays.startRequestId));
  expect(find.byKey(const ValueKey('start-workday-button')), findsOneWidget);
}

void _expectValidPosition(LocationSample? location) {
  expect(location, isNotNull);
  expect(location!.latitude, inInclusiveRange(-90, 90));
  expect(location.longitude, inInclusiveRange(-180, 180));
  expect(location.accuracyMeters, greaterThanOrEqualTo(0));
}
