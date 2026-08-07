import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/repositories/auth_repository.dart';
import '../data/repositories/customer_repository.dart';
import '../ui/auth/auth_view_model.dart';
import '../ui/auth/forgot_password/forgot_password_screen.dart';
import '../ui/auth/login/login_screen.dart';
import '../ui/auth/reset_password/reset_password_screen.dart';
import '../ui/auth/session_loading_screen.dart';
import '../ui/home/home_screen.dart';
import '../ui/customers/customer_list_screen.dart';
import '../ui/sync/sync_screen.dart';
import '../ui/sync/sync_view_model.dart';
import '../ui/workday/close_workday_screen.dart';
import '../ui/workday/workday_view_model.dart';

abstract final class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';
  static const home = '/home';
  static const closeWorkday = '/workday/close';
  static const sync = '/sync';
  static const customers = '/customers';
}

abstract final class AppRouter {
  static GoRouter create({
    required AuthViewModel authViewModel,
    required AuthRepository authRepository,
    required WorkdayViewModel workdayViewModel,
    required SyncViewModel syncViewModel,
    required CustomerRepository customerRepository,
    String initialLocation = AppRoutes.splash,
  }) {
    return GoRouter(
      initialLocation: initialLocation,
      refreshListenable: authViewModel,
      redirect: (context, state) {
        final path = state.uri.path;
        final status = authViewModel.status;

        if (status == AuthStatus.restoring) {
          return path == AppRoutes.splash ? null : AppRoutes.splash;
        }

        final isAuthenticated = status == AuthStatus.authenticated;
        final isPublicRoute =
            path == AppRoutes.login ||
            path == AppRoutes.forgotPassword ||
            path == AppRoutes.resetPassword;

        if (!isAuthenticated) {
          return isPublicRoute ? null : AppRoutes.login;
        }

        if (path == AppRoutes.splash ||
            path == AppRoutes.login ||
            path == AppRoutes.forgotPassword) {
          return AppRoutes.home;
        }

        return null;
      },
      routes: [
        GoRoute(
          path: AppRoutes.splash,
          builder: (context, state) => const SessionLoadingScreen(),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => LoginScreen(viewModel: authViewModel),
        ),
        GoRoute(
          path: AppRoutes.forgotPassword,
          builder: (context, state) =>
              ForgotPasswordScreen(repository: authRepository),
        ),
        GoRoute(
          path: AppRoutes.resetPassword,
          builder: (context, state) => ResetPasswordScreen(
            repository: authRepository,
            initialToken: state.uri.queryParameters['token'] ?? '',
          ),
        ),
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => HomeScreen(
            authViewModel: authViewModel,
            workdayViewModel: workdayViewModel,
          ),
        ),
        GoRoute(
          path: AppRoutes.closeWorkday,
          builder: (context, state) =>
              CloseWorkdayScreen(viewModel: workdayViewModel),
        ),
        GoRoute(
          path: AppRoutes.sync,
          builder: (context, state) => SyncScreen(viewModel: syncViewModel),
        ),
        GoRoute(
          path: AppRoutes.customers,
          builder: (context, state) =>
              CustomerListScreen(repository: customerRepository),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => context.go(AppRoutes.login),
            child: const Text('Volver al inicio'),
          ),
        ),
      ),
    );
  }
}
