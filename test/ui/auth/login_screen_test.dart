import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urbantrack/data/models/auth/auth_session.dart';
import 'package:urbantrack/data/repositories/auth_repository.dart';
import 'package:urbantrack/data/services/api_exception.dart';
import 'package:urbantrack/ui/auth/auth_view_model.dart';
import 'package:urbantrack/ui/auth/login/login_screen.dart';
import 'package:urbantrack/ui/core/branding/brand_scope.dart';
import 'package:urbantrack/ui/core/branding/urbantrack_brand.dart';
import 'package:urbantrack/ui/core/theme/app_theme.dart';

void main() {
  testWidgets('disables login while pending and renders the API error', (
    tester,
  ) async {
    final repository = _PendingLoginRepository();
    final viewModel = AuthViewModel(repository);
    await viewModel.restoreSession();

    await tester.pumpWidget(
      BrandScope(
        brand: UrbanTrackBrand.config,
        child: MaterialApp(
          theme: AppTheme.light(UrbanTrackBrand.config),
          home: LoginScreen(viewModel: viewModel),
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Correo electrónico'),
      'seller@example.test',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña'),
      'wrong-password',
    );

    final loginButton = find.widgetWithText(FilledButton, 'Ingresar');
    await tester.tap(loginButton);
    await tester.tap(loginButton);

    expect(repository.loginCalls, 1);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    repository.fail(
      const ApiException(
        statusCode: 401,
        message: 'La contraseña ingresada es incorrecta.',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login-error')), findsOneWidget);
    expect(find.text('La contraseña ingresada es incorrecta.'), findsOneWidget);
    expect(find.text('Ingresar'), findsOneWidget);
  });
}

class _PendingLoginRepository implements AuthRepository {
  final _loginCompleter = Completer<AuthSession>();
  int loginCalls = 0;

  void fail(Object error) => _loginCompleter.completeError(error);

  @override
  Future<String> forgotPassword(String email) async => 'Instructions sent.';

  @override
  Future<AuthSession?> restoreSession() async => null;

  @override
  Future<AuthSession> login({required String email, required String password}) {
    loginCalls += 1;
    return _loginCompleter.future;
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
