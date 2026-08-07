import 'package:flutter_test/flutter_test.dart';
import 'package:urbantrack/app/urbantrack_app.dart';
import 'package:urbantrack/config/app_environment.dart';
import 'package:urbantrack/data/models/auth/auth_session.dart';
import 'package:urbantrack/data/repositories/auth_repository.dart';
import 'package:urbantrack/ui/core/branding/urbantrack_brand.dart';

void main() {
  testWidgets('shows the UrbanTrack login shell', (tester) async {
    await tester.pumpWidget(
      UrbanTrackApp(
        brand: UrbanTrackBrand.config,
        environment: const AppEnvironment(apiBaseUrl: 'https://example.test'),
        authRepository: _SignedOutAuthRepository(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bienvenido a UrbanTrack'), findsOneWidget);
    expect(find.text('Correo electrónico'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.text('Ingresar'), findsOneWidget);
  });
}

class _SignedOutAuthRepository implements AuthRepository {
  @override
  Future<AuthSession?> restoreSession() async => null;

  @override
  Future<AuthSession> login({required String email, required String password}) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout(AuthSession session) async {}
}
