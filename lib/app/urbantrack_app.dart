import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/app_environment.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/customer_repository.dart';
import '../data/repositories/project_repository.dart';
import '../data/repositories/sync_repository.dart';
import '../data/repositories/visit_repository.dart';
import '../data/repositories/project_attachment_repository.dart';
import '../data/repositories/workday_repository.dart';
import '../data/repositories/history_repository.dart';
import '../data/services/connectivity_sync_coordinator.dart';
import '../data/services/location_service.dart';
import '../data/services/attachment_picker_service.dart';
import '../data/services/network_status_service.dart';
import '../routing/app_router.dart';
import '../ui/auth/auth_view_model.dart';
import '../ui/core/branding/brand_config.dart';
import '../ui/core/branding/brand_scope.dart';
import '../ui/core/theme/app_theme.dart';
import '../ui/sync/sync_view_model.dart';
import '../ui/workday/workday_view_model.dart';

class UrbanTrackApp extends StatelessWidget {
  const UrbanTrackApp({
    required this.brand,
    required this.environment,
    required this.authRepository,
    required this.workdayRepository,
    required this.locationService,
    required this.networkStatusService,
    required this.syncRepository,
    required this.customerRepository,
    required this.projectRepository,
    required this.visitRepository,
    required this.attachmentRepository,
    required this.historyRepository,
    this.attachmentPickerService,
    super.key,
  });

  final BrandConfig brand;
  final AppEnvironment environment;
  final AuthRepository authRepository;
  final WorkdayRepository workdayRepository;
  final LocationService locationService;
  final NetworkStatusService networkStatusService;
  final SyncRepository syncRepository;
  final CustomerRepository customerRepository;
  final ProjectRepository projectRepository;
  final VisitRepository visitRepository;
  final ProjectAttachmentRepository attachmentRepository;
  final HistoryRepository historyRepository;
  final AttachmentPickerService? attachmentPickerService;

  @override
  Widget build(BuildContext context) {
    return _AppHost(
      authRepository: authRepository,
      workdayRepository: workdayRepository,
      locationService: locationService,
      networkStatusService: networkStatusService,
      syncRepository: syncRepository,
      customerRepository: customerRepository,
      projectRepository: projectRepository,
      visitRepository: visitRepository,
      attachmentRepository: attachmentRepository,
      historyRepository: historyRepository,
      attachmentPickerService: attachmentPickerService,
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
  const _AppHost({
    required this.authRepository,
    required this.workdayRepository,
    required this.locationService,
    required this.networkStatusService,
    required this.syncRepository,
    required this.customerRepository,
    required this.projectRepository,
    required this.visitRepository,
    required this.attachmentRepository,
    required this.historyRepository,
    this.attachmentPickerService,
    required this.builder,
  });

  final AuthRepository authRepository;
  final WorkdayRepository workdayRepository;
  final LocationService locationService;
  final NetworkStatusService networkStatusService;
  final SyncRepository syncRepository;
  final CustomerRepository customerRepository;
  final ProjectRepository projectRepository;
  final VisitRepository visitRepository;
  final ProjectAttachmentRepository attachmentRepository;
  final HistoryRepository historyRepository;
  final AttachmentPickerService? attachmentPickerService;
  final Widget Function(GoRouter router) builder;

  @override
  State<_AppHost> createState() => _AppHostState();
}

class _AppHostState extends State<_AppHost> {
  late final AuthViewModel _authViewModel;
  late final WorkdayViewModel _workdayViewModel;
  late final SyncViewModel _syncViewModel;
  late final ConnectivitySyncCoordinator _syncCoordinator;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authViewModel = AuthViewModel(widget.authRepository);
    _workdayViewModel = WorkdayViewModel(
      widget.workdayRepository,
      widget.locationService,
    );
    _syncViewModel = SyncViewModel(
      widget.syncRepository,
      widget.networkStatusService,
    );
    unawaited(_syncViewModel.initialize());
    _syncCoordinator = ConnectivitySyncCoordinator(
      widget.networkStatusService,
      widget.syncRepository,
      onSynced: () async {
        if (_authViewModel.status == AuthStatus.authenticated) {
          await _workdayViewModel.loadCurrent();
        }
        await _syncViewModel.load();
      },
    )..start();
    _router = AppRouter.create(
      authViewModel: _authViewModel,
      authRepository: widget.authRepository,
      workdayViewModel: _workdayViewModel,
      workdayRepository: widget.workdayRepository,
      syncViewModel: _syncViewModel,
      customerRepository: widget.customerRepository,
      projectRepository: widget.projectRepository,
      visitRepository: widget.visitRepository,
      attachmentRepository: widget.attachmentRepository,
      historyRepository: widget.historyRepository,
      locationService: widget.locationService,
      attachmentPickerService: widget.attachmentPickerService,
    );
    _authViewModel.restoreSession();
  }

  @override
  void dispose() {
    unawaited(_syncCoordinator.dispose());
    _router.dispose();
    _syncViewModel.dispose();
    _workdayViewModel.dispose();
    _authViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(_router);
}
