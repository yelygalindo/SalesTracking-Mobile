import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urbantrack/app/urbantrack_app.dart';
import 'package:urbantrack/config/app_environment.dart';
import 'package:urbantrack/data/models/auth/auth_session.dart';
import 'package:urbantrack/data/models/auth/user_profile.dart';
import 'package:urbantrack/data/models/workday/current_workday_response.dart';
import 'package:urbantrack/data/repositories/auth_repository.dart';
import 'package:urbantrack/data/services/network_status_service.dart';
import 'package:urbantrack/ui/core/branding/urbantrack_brand.dart';

import 'support/workday_test_doubles.dart';

void main() {
  testWidgets(
    'connectivity does not load authenticated resources before login',
    (tester) async {
      final network = _ControlledNetworkStatusService();
      final workdays = _RecordingWorkdayRepository();
      addTearDown(network.dispose);

      await tester.pumpWidget(
        UrbanTrackApp(
          brand: UrbanTrackBrand.config,
          environment: const AppEnvironment(apiBaseUrl: 'https://example.test'),
          authRepository: _SignedOutThenLoginAuthRepository(),
          workdayRepository: workdays,
          locationService: FixedLocationService(),
          networkStatusService: network,
          syncRepository: EmptySyncRepository(),
          customerRepository: EmptyCustomerRepository(),
          projectRepository: EmptyProjectRepository(),
          visitRepository: EmptyVisitRepository(),
          attachmentRepository: EmptyAttachmentRepository(),
          historyRepository: EmptyHistoryRepository(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Bienvenido a UrbanTrackCRM'), findsOneWidget);

      network.controller.add(true);
      await tester.pumpAndSettle();
      expect(workdays.getCurrentCalls, 0);
      expect(find.textContaining('Tu sesión expiró'), findsNothing);

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'seller@example.test',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'password');
      await tester.tap(find.text('Ingresar'));
      await tester.pumpAndSettle();

      expect(workdays.getCurrentCalls, 1);
      expect(find.text('Iniciar jornada'), findsOneWidget);
      expect(find.textContaining('Tu sesión expiró'), findsNothing);
    },
  );
}

class _SignedOutThenLoginAuthRepository implements AuthRepository {
  final AuthSession _session = AuthSession(
    user: const UserProfile(
      id: 1,
      externalId: 'seller-id',
      username: 'seller',
      fullName: 'Vendedor de prueba',
      email: 'seller@example.test',
      roles: ['Seller'],
      permissions: [],
    ),
    accessToken: 'access-token',
    refreshToken: 'refresh-token',
    expiresAtUtc: DateTime.utc(2099),
  );

  @override
  Future<String> forgotPassword(String email) async => 'Instructions sent.';

  @override
  Future<AuthSession> login({required String email, required String password}) {
    return Future.value(_session);
  }

  @override
  Future<void> logout(AuthSession session) async {}

  @override
  Future<String> resetPassword({
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async => 'Password updated.';

  @override
  Future<AuthSession?> restoreSession() async => null;
}

class _RecordingWorkdayRepository extends InactiveWorkdayRepository {
  int getCurrentCalls = 0;

  @override
  Future<CurrentWorkdayResponse> getCurrent() async {
    getCurrentCalls += 1;
    return super.getCurrent();
  }
}

class _ControlledNetworkStatusService implements NetworkStatusService {
  final StreamController<bool> controller = StreamController<bool>.broadcast();

  @override
  Future<bool> get isConnected async => true;

  @override
  Stream<bool> get changes => controller.stream;

  Future<void> dispose() => controller.close();
}
