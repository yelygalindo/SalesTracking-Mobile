import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/repositories/auth_repository.dart';
import '../data/repositories/customer_repository.dart';
import '../data/repositories/project_repository.dart';
import '../data/repositories/visit_repository.dart';
import '../data/repositories/workday_repository.dart';
import '../data/repositories/project_attachment_repository.dart';
import '../data/repositories/history_repository.dart';
import '../data/models/visit/visit_target_type.dart';
import '../data/services/location_service.dart';
import '../data/services/attachment_picker_service.dart';
import '../ui/auth/auth_view_model.dart';
import '../ui/auth/forgot_password/forgot_password_screen.dart';
import '../ui/auth/login/login_screen.dart';
import '../ui/auth/reset_password/reset_password_screen.dart';
import '../ui/auth/session_loading_screen.dart';
import '../ui/home/home_screen.dart';
import '../ui/customers/customer_list_screen.dart';
import '../ui/customers/customer_detail_screen.dart';
import '../ui/customers/customer_form_screen.dart';
import '../ui/projects/project_detail_screen.dart';
import '../ui/projects/project_form_screen.dart';
import '../ui/projects/project_list_screen.dart';
import '../ui/sync/sync_screen.dart';
import '../ui/sync/sync_view_model.dart';
import '../ui/workday/close_workday_screen.dart';
import '../ui/workday/workday_view_model.dart';
import '../ui/visits/visit_check_in_screen.dart';
import '../ui/visits/visit_check_out_screen.dart';
import '../ui/attachments/project_attachment_screen.dart';
import '../ui/history/history_screen.dart';
import '../ui/history/project_visits_screen.dart';

abstract final class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';
  static const home = '/home';
  static const closeWorkday = '/workday/close';
  static const sync = '/sync';
  static const customers = '/customers';
  static const newCustomer = '/customers/new';
  static const projects = '/projects';
  static const newProject = '/projects/new';
  static const visitCheckOut = '/visits/check-out';
  static const history = '/history';

  static String projectAttachments(
    String projectExternalId,
    String visitExternalId,
  ) => Uri(
    path: '/projects/${Uri.encodeComponent(projectExternalId)}/attachments/new',
    queryParameters: {'visitId': visitExternalId},
  ).toString();

  static String projectVisits(String projectExternalId, String projectName) =>
      Uri(
        path: '/projects/${Uri.encodeComponent(projectExternalId)}/visits',
        queryParameters: {'name': projectName},
      ).toString();

  static String customerDetail(String externalId) =>
      '/customers/${Uri.encodeComponent(externalId)}';

  static String editCustomer(String externalId) =>
      '${customerDetail(externalId)}/edit';

  static String projectDetail(String externalId) =>
      '/projects/${Uri.encodeComponent(externalId)}';

  static String editProject(String externalId) =>
      '${projectDetail(externalId)}/edit';

  static String visitCheckIn(
    VisitTargetType type,
    String targetExternalId,
    String targetName,
  ) => Uri(
    path: '/visits/check-in',
    queryParameters: {
      'type': type.name,
      'targetId': targetExternalId,
      'targetName': targetName,
    },
  ).toString();
}

abstract final class AppRouter {
  static GoRouter create({
    required AuthViewModel authViewModel,
    required AuthRepository authRepository,
    required WorkdayViewModel workdayViewModel,
    required WorkdayRepository workdayRepository,
    required SyncViewModel syncViewModel,
    required CustomerRepository customerRepository,
    required ProjectRepository projectRepository,
    required VisitRepository visitRepository,
    required ProjectAttachmentRepository attachmentRepository,
    required HistoryRepository historyRepository,
    required LocationService locationService,
    AttachmentPickerService? attachmentPickerService,
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
          path: AppRoutes.history,
          builder: (context, state) =>
              HistoryScreen(repository: historyRepository),
        ),
        GoRoute(
          path: '/visits/check-in',
          builder: (context, state) => VisitCheckInScreen(
            repository: visitRepository,
            workdayRepository: workdayRepository,
            locationService: locationService,
            targetType: state.uri.queryParameters['type'] == 'project'
                ? VisitTargetType.project
                : VisitTargetType.customer,
            targetExternalId: state.uri.queryParameters['targetId'] ?? '',
            targetName: state.uri.queryParameters['targetName'] ?? 'Sin nombre',
          ),
        ),
        GoRoute(
          path: AppRoutes.visitCheckOut,
          builder: (context, state) => VisitCheckOutScreen(
            repository: visitRepository,
            locationService: locationService,
          ),
        ),
        GoRoute(
          path: AppRoutes.customers,
          builder: (context, state) =>
              CustomerListScreen(repository: customerRepository),
        ),
        GoRoute(
          path: AppRoutes.projects,
          builder: (context, state) => ProjectListScreen(
            projectRepository: projectRepository,
            customerRepository: customerRepository,
          ),
        ),
        GoRoute(
          path: AppRoutes.newProject,
          builder: (context, state) => ProjectFormScreen(
            projectRepository: projectRepository,
            customerRepository: customerRepository,
            locationService: locationService,
          ),
        ),
        GoRoute(
          path: '/projects/:externalId/attachments/new',
          builder: (context, state) => ProjectAttachmentScreen(
            repository: attachmentRepository,
            projectExternalId: state.pathParameters['externalId']!,
            visitExternalId: state.uri.queryParameters['visitId'] ?? '',
            pickerService: attachmentPickerService,
          ),
        ),
        GoRoute(
          path: '/projects/:externalId/visits',
          builder: (context, state) => ProjectVisitsScreen(
            repository: historyRepository,
            projectExternalId: state.pathParameters['externalId']!,
            projectName: state.uri.queryParameters['name'] ?? '',
          ),
        ),
        GoRoute(
          path: '/projects/:externalId',
          builder: (context, state) => ProjectDetailScreen(
            repository: projectRepository,
            visitRepository: visitRepository,
            externalId: state.pathParameters['externalId']!,
          ),
        ),
        GoRoute(
          path: '/projects/:externalId/edit',
          builder: (context, state) => ProjectFormScreen(
            projectRepository: projectRepository,
            customerRepository: customerRepository,
            locationService: locationService,
            externalId: state.pathParameters['externalId']!,
          ),
        ),
        GoRoute(
          path: AppRoutes.newCustomer,
          builder: (context, state) => CustomerFormScreen(
            repository: customerRepository,
            locationService: locationService,
          ),
        ),
        GoRoute(
          path: '/customers/:externalId',
          builder: (context, state) => CustomerDetailScreen(
            repository: customerRepository,
            visitRepository: visitRepository,
            externalId: state.pathParameters['externalId']!,
          ),
        ),
        GoRoute(
          path: '/customers/:externalId/edit',
          builder: (context, state) => CustomerFormScreen(
            repository: customerRepository,
            locationService: locationService,
            externalId: state.pathParameters['externalId']!,
          ),
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
