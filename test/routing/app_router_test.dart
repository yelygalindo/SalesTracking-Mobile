import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urbantrack/data/models/auth/auth_session.dart';
import 'package:urbantrack/data/repositories/auth_repository.dart';
import 'package:urbantrack/routing/app_router.dart';
import 'package:urbantrack/ui/auth/auth_view_model.dart';
import 'package:urbantrack/ui/core/branding/brand_scope.dart';
import 'package:urbantrack/ui/core/branding/urbantrack_brand.dart';
import 'package:urbantrack/ui/core/theme/app_theme.dart';
import 'package:urbantrack/ui/sync/sync_view_model.dart';
import 'package:urbantrack/ui/workday/workday_view_model.dart';

import '../support/workday_test_doubles.dart';

void main() {
  testWidgets('prefills a reset token received in the route', (tester) async {
    final repository = _SignedOutRepository();
    final authViewModel = AuthViewModel(repository);
    final workdayViewModel = WorkdayViewModel(
      InactiveWorkdayRepository(),
      FixedLocationService(),
    );
    final syncViewModel = SyncViewModel(
      EmptySyncRepository(),
      DisconnectedNetworkStatusService(),
    );
    await authViewModel.restoreSession();
    final router = AppRouter.create(
      authViewModel: authViewModel,
      authRepository: repository,
      workdayViewModel: workdayViewModel,
      syncViewModel: syncViewModel,
      customerRepository: EmptyCustomerRepository(),
      projectRepository: EmptyProjectRepository(),
      locationService: FixedLocationService(),
      initialLocation: '${AppRoutes.resetPassword}?token=route-token',
    );

    await tester.pumpWidget(
      BrandScope(
        brand: UrbanTrackBrand.config,
        child: MaterialApp.router(
          theme: AppTheme.light(UrbanTrackBrand.config),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Crea una nueva contraseña'), findsOneWidget);
    expect(find.text('route-token'), findsOneWidget);

    router.dispose();
    workdayViewModel.dispose();
    syncViewModel.dispose();
    authViewModel.dispose();
  });
}

class _SignedOutRepository implements AuthRepository {
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
