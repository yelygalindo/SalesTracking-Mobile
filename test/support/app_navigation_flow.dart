import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urbantrack/app/urbantrack_app.dart';
import 'package:urbantrack/config/app_environment.dart';
import 'package:urbantrack/data/models/auth/auth_session.dart';
import 'package:urbantrack/data/models/auth/user_profile.dart';
import 'package:urbantrack/data/repositories/auth_repository.dart';
import 'package:urbantrack/ui/core/branding/urbantrack_brand.dart';

import 'workday_test_doubles.dart';

Future<void> runAppNavigationFlow(WidgetTester tester) async {
  final authRepository = _SignedInAuthRepository();

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

class _SignedInAuthRepository implements AuthRepository {
  int logoutCalls = 0;

  final AuthSession _session = AuthSession(
    user: const UserProfile(
      id: 1,
      externalId: 'seller-test-id',
      username: 'seller.test',
      fullName: 'Vendedor de prueba',
      email: 'seller@example.test',
      roles: ['Seller'],
      permissions: [],
    ),
    accessToken: 'test-access-token',
    refreshToken: 'test-refresh-token',
    expiresAtUtc: DateTime.utc(2099),
  );

  @override
  Future<String> forgotPassword(String email) async => 'Instructions sent.';

  @override
  Future<AuthSession> login({required String email, required String password}) {
    return Future.value(_session);
  }

  @override
  Future<void> logout(AuthSession session) async {
    logoutCalls += 1;
  }

  @override
  Future<String> resetPassword({
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async => 'Password updated.';

  @override
  Future<AuthSession?> restoreSession() async => _session;
}
