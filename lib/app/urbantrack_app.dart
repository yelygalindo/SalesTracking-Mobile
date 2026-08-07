import 'package:flutter/material.dart';

import '../config/app_environment.dart';
import '../data/repositories/auth_repository.dart';
import '../ui/auth/auth_shell.dart';
import '../ui/auth/auth_view_model.dart';
import '../ui/core/branding/brand_config.dart';
import '../ui/core/branding/brand_scope.dart';
import '../ui/core/theme/app_theme.dart';

class UrbanTrackApp extends StatelessWidget {
  const UrbanTrackApp({
    required this.brand,
    required this.environment,
    required this.authRepository,
    super.key,
  });

  final BrandConfig brand;
  final AppEnvironment environment;
  final AuthRepository authRepository;

  @override
  Widget build(BuildContext context) {
    return _AuthViewModelHost(
      authRepository: authRepository,
      builder: (authViewModel) => BrandScope(
        brand: brand,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: brand.appName,
          theme: AppTheme.light(brand),
          home: AuthShell(viewModel: authViewModel),
        ),
      ),
    );
  }
}

class _AuthViewModelHost extends StatefulWidget {
  const _AuthViewModelHost({
    required this.authRepository,
    required this.builder,
  });

  final AuthRepository authRepository;
  final Widget Function(AuthViewModel viewModel) builder;

  @override
  State<_AuthViewModelHost> createState() => _AuthViewModelHostState();
}

class _AuthViewModelHostState extends State<_AuthViewModelHost> {
  late final AuthViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = AuthViewModel(widget.authRepository)..restoreSession();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(_viewModel);
}
