import 'package:flutter/material.dart';

import '../home/home_screen.dart';
import 'auth_view_model.dart';
import 'login/login_screen.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({required this.viewModel, super.key});

  final AuthViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        return switch (viewModel.status) {
          AuthStatus.restoring => const _SessionLoadingScreen(),
          AuthStatus.unauthenticated ||
          AuthStatus.authenticating => LoginScreen(viewModel: viewModel),
          AuthStatus.authenticated => HomeScreen(viewModel: viewModel),
        };
      },
    );
  }
}

class _SessionLoadingScreen extends StatelessWidget {
  const _SessionLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
