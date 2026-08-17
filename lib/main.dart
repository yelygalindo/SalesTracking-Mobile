import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import 'app/urbantrack_app.dart';
import 'config/app_environment.dart';
import 'data/repositories/composite_sync_repository.dart';
import 'data/repositories/attachment_sync_repository.dart';
import 'data/repositories/customer_sync_repository.dart';
import 'data/repositories/sync_repository.dart';
import 'data/repositories/offline_first_customer_repository.dart';
import 'data/repositories/offline_first_workday_repository.dart';
import 'data/repositories/offline_first_visit_repository.dart';
import 'data/repositories/offline_first_project_attachment_repository.dart';
import 'data/repositories/remote_auth_repository.dart';
import 'data/repositories/remote_customer_repository.dart';
import 'data/repositories/remote_project_repository.dart';
import 'data/repositories/offline_first_project_repository.dart';
import 'data/repositories/sqflite_project_local_store.dart';
import 'data/repositories/remote_workday_repository.dart';
import 'data/repositories/remote_visit_repository.dart';
import 'data/repositories/remote_project_attachment_repository.dart';
import 'data/repositories/remote_history_repository.dart';
import 'data/repositories/sqflite_customer_local_store.dart';
import 'data/repositories/sqflite_workday_local_store.dart';
import 'data/repositories/sqflite_visit_local_store.dart';
import 'data/repositories/sqflite_attachment_local_store.dart';
import 'data/repositories/visit_sync_repository.dart';
import 'data/repositories/workday_sync_repository.dart';
import 'data/services/auth_service.dart';
import 'data/services/api_exception.dart';
import 'data/services/connectivity_network_status_service.dart';
import 'data/services/customer_service.dart';
import 'data/services/geolocator_location_service.dart';
import 'data/services/project_service.dart';
import 'data/services/workday_service.dart';
import 'data/services/visit_service.dart';
import 'data/services/project_attachment_service.dart';
import 'data/services/history_service.dart';
import 'data/storage/app_database.dart';
import 'data/storage/secure_session_storage.dart';
import 'data/storage/device_attachment_file_store.dart';
import 'ui/core/branding/urbantrack_brand.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final environment = AppEnvironment.current;
  final authHttpClient = http.Client();
  final sessionStorage = SecureSessionStorage(const FlutterSecureStorage());
  final networkStatusService = ConnectivityNetworkStatusService();
  final appDatabase = AppDatabase();
  late final SyncRepository syncRepository;
  final authRepository = RemoteAuthRepository(
    AuthService(Uri.parse(environment.apiBaseUrl), authHttpClient),
    sessionStorage,
    Platform.isIOS ? 'ios' : 'android',
    onPrepareForUser: (previousUserId, nextUserId) async {
      final pending = await syncRepository.getPending();
      if (pending.isNotEmpty) {
        throw ApiException(
          message:
              'Este dispositivo conserva ${pending.length} operación(es) '
              'pendiente(s) de la cuenta anterior. Sincronízalas con esa '
              'cuenta antes de cambiar de usuario.',
        );
      }
      await appDatabase.clearCachedState();
    },
  );
  final remoteWorkdayRepository = RemoteWorkdayRepository(
    WorkdayService(Uri.parse(environment.apiBaseUrl), http.Client()),
    authRepository,
  );
  final workdayLocalStore = SqfliteWorkdayLocalStore(appDatabase);
  final workdayRepository = OfflineFirstWorkdayRepository(
    remoteWorkdayRepository,
    workdayLocalStore,
    networkStatusService,
  );
  final workdaySyncRepository = WorkdaySyncRepository(
    workdayLocalStore,
    workdayRepository,
  );
  final remoteCustomerRepository = RemoteCustomerRepository(
    CustomerService(Uri.parse(environment.apiBaseUrl), http.Client()),
    authRepository,
  );
  final customerLocalStore = SqfliteCustomerLocalStore(appDatabase);
  final customerRepository = OfflineFirstCustomerRepository(
    remoteCustomerRepository,
    customerLocalStore,
    networkStatusService,
  );
  final remoteProjectRepository = RemoteProjectRepository(
    ProjectService(Uri.parse(environment.apiBaseUrl), http.Client()),
    authRepository,
  );
  final projectRepository = OfflineFirstProjectRepository(
    remoteProjectRepository,
    SqfliteProjectLocalStore(appDatabase),
    networkStatusService,
  );
  final visitLocalStore = SqfliteVisitLocalStore(appDatabase);
  final visitRepository = OfflineFirstVisitRepository(
    RemoteVisitRepository(
      VisitService(Uri.parse(environment.apiBaseUrl), http.Client()),
      authRepository,
    ),
    visitLocalStore,
    networkStatusService,
  );
  final attachmentLocalStore = SqfliteAttachmentLocalStore(appDatabase);
  final attachmentRepository = OfflineFirstProjectAttachmentRepository(
    RemoteProjectAttachmentRepository(
      ProjectAttachmentService(
        Uri.parse(environment.apiBaseUrl),
        http.Client(),
      ),
      authRepository,
    ),
    attachmentLocalStore,
    visitLocalStore,
    const DeviceAttachmentFileStore(),
    networkStatusService,
  );
  final historyRepository = RemoteHistoryRepository(
    HistoryService(Uri.parse(environment.apiBaseUrl), http.Client()),
    authRepository,
  );
  syncRepository = CompositeSyncRepository([
    workdaySyncRepository,
    CustomerSyncRepository(customerLocalStore, customerRepository),
    VisitSyncRepository(visitLocalStore, visitRepository),
    AttachmentSyncRepository(attachmentLocalStore, attachmentRepository),
  ]);

  runApp(
    UrbanTrackApp(
      brand: UrbanTrackBrand.config,
      environment: environment,
      authRepository: authRepository,
      workdayRepository: workdayRepository,
      locationService: const GeolocatorLocationService(),
      networkStatusService: networkStatusService,
      syncRepository: syncRepository,
      customerRepository: customerRepository,
      projectRepository: projectRepository,
      visitRepository: visitRepository,
      attachmentRepository: attachmentRepository,
      historyRepository: historyRepository,
    ),
  );
}
