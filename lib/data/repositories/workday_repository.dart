import '../models/common/location_sample.dart';
import '../models/workday/current_workday_response.dart';
import '../models/workday/workday.dart';

abstract interface class WorkdayRepository {
  Future<void> syncPending();

  Future<int> pendingCount();

  Future<CurrentWorkdayResponse> getCurrent();

  Future<Workday> start({
    required DateTime startedAtUtc,
    required LocationSample location,
    required String clientRequestId,
    String? note,
  });

  Future<Workday> close({
    required String externalId,
    required DateTime endedAtUtc,
    required LocationSample location,
    required String clientRequestId,
  });
}
