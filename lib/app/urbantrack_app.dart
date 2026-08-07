import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/app_environment.dart';
import '../data/repositories/auth_repository.dart';
import '../routing/app_router.dart';
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
    return _AppHost(
      authRepository: authRepository,
      builder: (router) => BrandScope(
        brand: brand,
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: brand.appName,
          theme: AppTheme.light(brand),
          routerConfig: router,
        ),
      ),
    );
  }
}

class _AppHost extends StatefulWidget {
  const _AppHost({required this.authRepository, required this.builder});

  final AuthRepository authRepository;
  final Widget Function(GoRouter router) builder;

  @override
  State<_AppHost> createState() => _AppHostState();
}

class _AppHostState extends State<_AppHost> {
  late final AuthViewModel _authViewModel;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authViewModel = AuthViewModel(widget.authRepository);
    _router = AppRouter.create(
      authViewModel: _authViewModel,
      authRepository: widget.authRepository,
    );
    _authViewModel.restoreSession();
  }

  @override
  void dispose() {
    _router.dispose();
    _authViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(_router);
}
