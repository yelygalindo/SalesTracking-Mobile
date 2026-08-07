import 'package:urbantrack/data/models/common/location_sample.dart';
import 'package:urbantrack/data/models/customer/customer_page.dart';
import 'package:urbantrack/data/models/customer/customer_status.dart';
import 'package:urbantrack/data/models/sync/sync_queue_entry.dart';
import 'package:urbantrack/data/models/workday/current_workday_response.dart';
import 'package:urbantrack/data/models/workday/workday.dart';
import 'package:urbantrack/data/repositories/workday_repository.dart';
import 'package:urbantrack/data/repositories/sync_repository.dart';
import 'package:urbantrack/data/repositories/customer_repository.dart';
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
}
