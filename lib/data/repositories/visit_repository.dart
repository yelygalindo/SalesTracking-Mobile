import '../models/common/location_sample.dart';
import '../models/visit/current_visit.dart';
import '../models/visit/visit_target_type.dart';

abstract interface class VisitRepository {
  Future<CurrentVisit?> getCurrent();

  Future<CurrentVisit> checkIn({
    required VisitTargetType targetType,
    required String targetExternalId,
    required String targetName,
    required DateTime checkInAtUtc,
    required LocationSample location,
    required String clientRequestId,
    String? note,
  });

  Future<void> checkOut({
    required CurrentVisit visit,
    required DateTime checkOutAtUtc,
    required LocationSample location,
    required String clientRequestId,
    String? note,
    String? result,
  });

  Future<int> pendingCount();

  Future<void> syncPending();
}
