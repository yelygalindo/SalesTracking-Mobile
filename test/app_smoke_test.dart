import 'package:flutter_test/flutter_test.dart';
import 'package:urbantrack/app/urbantrack_app.dart';
import 'package:urbantrack/config/app_environment.dart';
import 'package:urbantrack/data/models/auth/auth_session.dart';
import 'package:urbantrack/data/repositories/auth_repository.dart';
import 'package:urbantrack/ui/core/branding/urbantrack_brand.dart';

import 'support/workday_test_doubles.dart';

void main() {
  testWidgets('shows the UrbanTrack login shell', (tester) async {
    await tester.pumpWidget(
      UrbanTrackApp(
        brand: UrbanTrackBrand.config,
        environment: const AppEnvironment(apiBaseUrl: 'https://example.test'),
        authRepository: _SignedOutAuthRepository(),
        workdayRepository: InactiveWorkdayRepository(),
        locationService: FixedLocationService(),
        networkStatusService: DisconnectedNetworkStatusService(),
        syncRepository: EmptySyncRepository(),
        customerRepository: EmptyCustomerRepository(),
        projectRepository: EmptyProjectRepository(),
        visitRepository: EmptyVisitRepository(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bienvenido a UrbanTrack'), findsOneWidget);
    expect(find.text('Correo electrónico'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.text('Ingresar'), findsOneWidget);
  });

  testWidgets('navigates from login to password recovery', (tester) async {
    await tester.pumpWidget(
      UrbanTrackApp(
        brand: UrbanTrackBrand.config,
        environment: const AppEnvironment(apiBaseUrl: 'https://example.test'),
        authRepository: _SignedOutAuthRepository(),
        workdayRepository: InactiveWorkdayRepository(),
        locationService: FixedLocationService(),
        networkStatusService: DisconnectedNetworkStatusService(),
        syncRepository: EmptySyncRepository(),
        customerRepository: EmptyCustomerRepository(),
        projectRepository: EmptyProjectRepository(),
        visitRepository: EmptyVisitRepository(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('¿Olvidaste tu contraseña?'));
    await tester.pumpAndSettle();

    expect(find.text('Recupera tu contraseña'), findsOneWidget);
    expect(find.text('Enviar instrucciones'), findsOneWidget);
  });
}

class _SignedOutAuthRepository implements AuthRepository {
  @override
  Future<String> forgotPassword(String email) async => 'Instructions sent.';

  @override
  Future<AuthSession?> restoreSession() async => null;

  @override
  Future<AuthSession> login({required String email, required String password}) {
    throw UnimplementedError();
  }

  @override
  Future<String> resetPassword({
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async => 'Password updated.';

  @override
  Future<void> logout(AuthSession session) async {}
}
