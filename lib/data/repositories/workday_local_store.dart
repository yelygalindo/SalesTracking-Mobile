import '../models/workday/pending_workday_operation.dart';
import '../models/workday/workday.dart';

abstract interface class WorkdayLocalStore {
  Future<Workday?> readCurrent();

  Future<void> writeCurrent(Workday? workday);

  Future<void> enqueue(
    PendingWorkdayOperation operation, {
    required Workday current,
  });

  Future<List<PendingWorkdayOperation>> readPending();

  Future<int> pendingCount();

  Future<String?> serverIdForLocalId(String localWorkdayId);

  Future<void> markSynced(
    String requestId, {
    String? localWorkdayId,
    String? serverWorkdayId,
  });

  Future<void> recordFailure(String requestId, String message);
}
