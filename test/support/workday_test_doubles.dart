import 'package:urbantrack/data/models/common/location_sample.dart';
import 'package:urbantrack/data/models/customer/customer_page.dart';
import 'package:urbantrack/data/models/customer/customer_detail.dart';
import 'package:urbantrack/data/models/customer/customer_input.dart';
import 'package:urbantrack/data/models/customer/customer_status.dart';
import 'package:urbantrack/data/models/project/project_detail.dart';
import 'package:urbantrack/data/models/project/project_input.dart';
import 'package:urbantrack/data/models/project/project_page.dart';
import 'package:urbantrack/data/models/visit/current_visit.dart';
import 'package:urbantrack/data/models/visit/visit_target_type.dart';
import 'package:urbantrack/data/models/common/resource_creation_result.dart';
import 'package:urbantrack/data/models/sync/sync_queue_entry.dart';
import 'package:urbantrack/data/models/workday/current_workday_response.dart';
import 'package:urbantrack/data/models/workday/workday.dart';
import 'package:urbantrack/data/repositories/workday_repository.dart';
import 'package:urbantrack/data/repositories/sync_repository.dart';
import 'package:urbantrack/data/repositories/customer_repository.dart';
import 'package:urbantrack/data/repositories/project_repository.dart';
import 'package:urbantrack/data/repositories/visit_repository.dart';
import 'package:urbantrack/data/services/location_service.dart';
import 'package:urbantrack/data/services/network_status_service.dart';

class InactiveWorkdayRepository implements WorkdayRepository {
  @override
  Future<void> syncPending() async {}

  @override
  Future<int> pendingCount() async => 0;

  @override
  Future<CurrentWorkdayResponse> getCurrent() async =>
      const CurrentWorkdayResponse(hasOpenWorkday: false, workday: null);

  @override
  Future<Workday> start({
    required DateTime startedAtUtc,
    required LocationSample location,
    required String clientRequestId,
    String? note,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Workday> close({
    required String externalId,
    required DateTime endedAtUtc,
    required LocationSample location,
    required String clientRequestId,
  }) {
    throw UnimplementedError();
  }
}

class FixedLocationService implements LocationService {
  @override
  Future<LocationSample> captureCurrent() async => const LocationSample(
    latitude: -12.0464,
    longitude: -77.0428,
    accuracyMeters: 8,
  );
}

class DisconnectedNetworkStatusService implements NetworkStatusService {
  @override
  Future<bool> get isConnected async => false;

  @override
  Stream<bool> get changes => const Stream.empty();
}

class EmptySyncRepository implements SyncRepository {
  @override
  Future<List<SyncQueueEntry>> getPending() async => const [];

  @override
  Future<void> synchronize() async {}
}

class EmptyCustomerRepository implements CustomerRepository {
  @override
  Future<ResourceCreationResult> addNote(
    String externalId,
    String text,
    String clientRequestId,
  ) async => const ResourceCreationResult(id: 'note-id', message: 'Created');

  @override
  Future<ResourceCreationResult> addReminder(
    String externalId, {
    required String text,
    required DateTime reminderAtUtc,
    String? assignedToId,
  }) async =>
      const ResourceCreationResult(id: 'reminder-id', message: 'Created');

  @override
  Future<void> completeReminder(
    String customerExternalId,
    String reminderExternalId,
  ) async {}

  @override
  Future<void> changeStatus(String externalId, int statusId) async {}

  @override
  Future<ResourceCreationResult> createCustomer(
    CustomerInput input,
    String clientRequestId,
  ) async =>
      const ResourceCreationResult(id: 'customer-id', message: 'Created');

  @override
  Future<CustomerDetail> getCustomer(String externalId) {
    throw UnimplementedError();
  }

  @override
  Future<CustomerPage> getCustomers({
    String? status,
    String? externalUserId,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async => CustomerPage(
    customers: const [],
    page: page,
    pageSize: pageSize,
    totalItems: 0,
    totalPages: 0,
  );

  @override
  Future<List<CustomerStatus>> getStatuses() async => const [];

  @override
  Future<void> updateCustomer(String externalId, CustomerInput input) async {}
}

class EmptyProjectRepository implements ProjectRepository {
  @override
  Future<void> changeStatus(String externalId, int statusId) async {}

  @override
  Future<ProjectDetail> createProject(
    ProjectInput input,
    String clientRequestId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<ProjectDetail> getProject(String externalId) {
    throw UnimplementedError();
  }

  @override
  Future<ProjectPage> getProjects({
    String? status,
    String? customerId,
    String? sellerId,
    int page = 1,
    int pageSize = 20,
  }) async => ProjectPage(
    projects: const [],
    page: page,
    pageSize: pageSize,
    totalItems: 0,
    totalPages: 0,
  );

  @override
  Future<void> updateProject(String externalId, ProjectInput input) async {}
}

class EmptyVisitRepository implements VisitRepository {
  @override
  Future<CurrentVisit?> getCurrent() async => null;

  @override
  Future<CurrentVisit> checkIn({
    required VisitTargetType targetType,
    required String targetExternalId,
    required String targetName,
    required DateTime checkInAtUtc,
    required LocationSample location,
    required String clientRequestId,
    String? note,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> checkOut({
    required CurrentVisit visit,
    required DateTime checkOutAtUtc,
    required LocationSample location,
    required String clientRequestId,
    String? note,
    String? result,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<int> pendingCount() async => 0;

  @override
  Future<void> syncPending() async {}
}
