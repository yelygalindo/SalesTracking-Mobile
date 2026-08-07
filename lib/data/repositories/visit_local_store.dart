import '../models/visit/current_visit.dart';
import '../models/visit/pending_visit_operation.dart';

abstract interface class VisitLocalStore {
  Future<CurrentVisit?> readCurrent();

  Future<void> writeCurrent(CurrentVisit? visit);

  Future<void> enqueue(
    PendingVisitOperation operation, {
    required CurrentVisit? current,
  });

  Future<List<PendingVisitOperation>> readPending();

  Future<int> pendingCount();

  Future<String?> serverIdForLocalId(String localVisitId);

  Future<void> markSynced(
    String requestId, {
    String? localVisitId,
    String? serverVisitId,
  });

  Future<void> recordFailure(String requestId, String message);
}
