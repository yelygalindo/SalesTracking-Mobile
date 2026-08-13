import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urbantrack/app/urbantrack_app.dart';
import 'package:urbantrack/config/app_environment.dart';
import 'package:urbantrack/data/models/auth/auth_session.dart';
import 'package:urbantrack/data/models/auth/user_profile.dart';
import 'package:urbantrack/data/repositories/auth_repository.dart';
import 'package:urbantrack/ui/core/branding/urbantrack_brand.dart';

import '../support/workday_test_doubles.dart';

void main() {
  group('WCAG-oriented accessibility checks', () {
    testWidgets(
      'login has labeled controls, contrast and Android tap targets',
      (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          await _setPhoneSize(tester);
          await tester.pumpWidget(_app(_SignedOutAuthRepository()));
          await tester.pumpAndSettle();

          await _expectCoreGuidelines(tester);
        } finally {
          semantics.dispose();
        }
      },
    );

    testWidgets('authenticated shell meets core accessibility guidelines', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        await _setPhoneSize(tester);
        await tester.pumpWidget(_app(_SignedInAuthRepository()));
        await tester.pumpAndSettle();

        await _expectCoreGuidelines(tester);

        for (final destination in const [
          'primary-nav-customers',
          'primary-nav-projects',
          'primary-nav-history',
        ]) {
          await tester.tap(find.byKey(ValueKey(destination)));
          await tester.pumpAndSettle();
          await _expectCoreGuidelines(tester);
        }
      } finally {
        semantics.dispose();
      }
    });
  });
}

Future<void> _expectCoreGuidelines(WidgetTester tester) async {
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));
}

UrbanTrackApp _app(AuthRepository authRepository) => UrbanTrackApp(
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
);

Future<void> _setPhoneSize(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

class _SignedOutAuthRepository implements AuthRepository {
  @override
  Future<String> forgotPassword(String email) async => 'Instructions sent.';

  @override
  Future<AuthSession> login({required String email, required String password}) {
    throw UnimplementedError();
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

class _SignedInAuthRepository extends _SignedOutAuthRepository {
  @override
  Future<AuthSession?> restoreSession() async => AuthSession(
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
}
