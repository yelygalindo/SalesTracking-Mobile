import 'package:urbantrack/data/models/common/location_sample.dart';
import 'package:urbantrack/data/models/customer/customer_page.dart';
import 'package:urbantrack/data/models/customer/customer_detail.dart';
import 'package:urbantrack/data/models/customer/customer_input.dart';
import 'package:urbantrack/data/models/customer/customer_status.dart';
import 'package:urbantrack/data/models/project/project_detail.dart';
import 'package:urbantrack/data/models/project/project_input.dart';
import 'package:urbantrack/data/models/project/project_note.dart';
import 'package:urbantrack/data/models/project/project_page.dart';
import 'package:urbantrack/data/models/project/project_status.dart';
import 'package:urbantrack/data/models/project/project_timeline_page.dart';
import 'package:urbantrack/data/models/visit/current_visit.dart';
import 'package:urbantrack/data/models/visit/visit_target_type.dart';
import 'package:urbantrack/data/models/attachment/attachment_save_result.dart';
import 'package:urbantrack/data/models/attachment/attachment_source_file.dart';
import 'package:urbantrack/data/models/attachment/attachment_upload_options.dart';
import 'package:urbantrack/data/models/attachment/project_attachment.dart';
import 'package:urbantrack/data/models/common/resource_creation_result.dart';
import 'package:urbantrack/data/models/sync/sync_queue_entry.dart';
import 'package:urbantrack/data/models/workday/current_workday_response.dart';
import 'package:urbantrack/data/models/workday/workday.dart';
import 'package:urbantrack/data/repositories/workday_repository.dart';
import 'package:urbantrack/data/repositories/sync_repository.dart';
import 'package:urbantrack/data/repositories/customer_repository.dart';
import 'package:urbantrack/data/repositories/project_repository.dart';
import 'package:urbantrack/data/repositories/visit_repository.dart';
import 'package:urbantrack/data/repositories/project_attachment_repository.dart';
import 'package:urbantrack/data/repositories/history_repository.dart';
import 'package:urbantrack/data/models/history/project_visit.dart';
import 'package:urbantrack/data/models/history/seller_timeline_page.dart';
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

class StatefulWorkdayRepository implements WorkdayRepository {
  Workday? current;
  int startCalls = 0;
  int closeCalls = 0;
  DateTime? startedAtUtc;
  DateTime? endedAtUtc;
  LocationSample? startLocation;
  LocationSample? closeLocation;
  String? startRequestId;
  String? closeRequestId;

  @override
  Future<void> syncPending() async {}

  @override
  Future<int> pendingCount() async => 0;

  @override
  Future<CurrentWorkdayResponse> getCurrent() async => CurrentWorkdayResponse(
    hasOpenWorkday: current?.isOpen == true,
    workday: current?.isOpen == true ? current : null,
  );

  @override
  Future<Workday> start({
    required DateTime startedAtUtc,
    required LocationSample location,
    required String clientRequestId,
    String? note,
  }) async {
    startCalls += 1;
    this.startedAtUtc = startedAtUtc;
    startLocation = location;
    startRequestId = clientRequestId;
    current = Workday(
      externalId: 'workday-test-id',
      status: 'open',
      startedAtUtc: startedAtUtc,
      startedReceivedAtUtc: startedAtUtc.add(const Duration(seconds: 2)),
      startLatitude: location.latitude,
      startLongitude: location.longitude,
      note: note,
    );
    return current!;
  }

  @override
  Future<Workday> close({
    required String externalId,
    required DateTime endedAtUtc,
    required LocationSample location,
    required String clientRequestId,
  }) async {
    closeCalls += 1;
    this.endedAtUtc = endedAtUtc;
    closeLocation = location;
    closeRequestId = clientRequestId;
    final open = current!;
    current = Workday(
      externalId: externalId,
      status: 'closed',
      startedAtUtc: open.startedAtUtc,
      startedReceivedAtUtc: open.startedReceivedAtUtc,
      startLatitude: open.startLatitude,
      startLongitude: open.startLongitude,
      note: open.note,
      endedAtUtc: endedAtUtc,
      endedReceivedAtUtc: endedAtUtc.add(const Duration(seconds: 2)),
      endLatitude: location.latitude,
      endLongitude: location.longitude,
    );
    return current!;
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
  Future<ResourceCreationResult> addNote(
    String projectExternalId, {
    required String content,
    required String clientRequestId,
    required DateTime occurredAtUtc,
  }) async => const ResourceCreationResult(id: 'note-id', message: 'Created');

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
  Future<List<ProjectNote>> getNotes(String projectExternalId) async =>
      const [];

  @override
  Future<List<ProjectStatus>> getStatuses() async => const [];

  @override
  Future<ProjectTimelinePage> getTimeline(
    String projectExternalId, {
    int page = 1,
    int pageSize = 50,
  }) async => ProjectTimelinePage(
    items: const [],
    page: page,
    pageSize: pageSize,
    totalItems: 0,
    totalPages: 0,
  );

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

class EmptyAttachmentRepository implements ProjectAttachmentRepository {
  @override
  Future<AttachmentUploadOptions> getOptions() async =>
      const AttachmentUploadOptions(
        maxFileSizeBytes: 0,
        attachmentTypes: [],
        acceptedFormats: [],
      );

  @override
  Future<List<ProjectAttachment>> getAttachments(
    String projectExternalId,
  ) async => const [];

  @override
  Future<AttachmentSaveResult> saveAttachments({
    required String projectExternalId,
    required List<AttachmentSourceFile> sources,
    required String attachmentType,
    String? visitExternalId,
    String? caption,
    bool isCover = false,
  }) async => AttachmentSaveResult(savedCount: sources.length, pendingCount: 0);

  @override
  Future<int> pendingCount() async => 0;

  @override
  Future<void> syncPending() async {}
}

class EmptyHistoryRepository implements HistoryRepository {
  @override
  Future<SellerTimelinePage> getMyTimeline({
    DateTime? from,
    DateTime? to,
    int page = 1,
    int pageSize = 30,
  }) async => SellerTimelinePage(
    items: const [],
    page: page,
    pageSize: pageSize,
    totalItems: 0,
    totalPages: 0,
  );

  @override
  Future<List<ProjectVisit>> getProjectVisits(
    String projectExternalId, {
    String? sellerExternalId,
    DateTime? from,
    DateTime? to,
  }) async => const [];
}
