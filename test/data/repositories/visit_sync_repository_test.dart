import 'package:flutter_test/flutter_test.dart';
import 'package:urbantrack/data/models/common/location_sample.dart';
import 'package:urbantrack/data/models/sync/sync_queue_entry.dart';
import 'package:urbantrack/data/models/visit/current_visit.dart';
import 'package:urbantrack/data/models/visit/pending_visit_operation.dart';
import 'package:urbantrack/data/models/visit/visit_target_type.dart';
import 'package:urbantrack/data/repositories/visit_local_store.dart';
import 'package:urbantrack/data/repositories/visit_repository.dart';
import 'package:urbantrack/data/repositories/visit_sync_repository.dart';

void main() {
  test('maps visit dependencies and delegates synchronization', () async {
    final local = _PendingVisitStore([
      PendingVisitOperation(
        requestId: 'check-in-id',
        localVisitId: 'local:check-in-id',
        type: PendingVisitOperationType.checkIn,
        targetType: VisitTargetType.project,
        targetExternalId: 'project-id',
        targetName: 'Obra Norte',
        occurredAtUtc: DateTime.utc(2026, 8, 7, 16),
        location: _location,
        createdAtUtc: DateTime.utc(2026, 8, 7, 16, 0, 1),
      ),
      PendingVisitOperation(
        requestId: 'check-out-id',
        localVisitId: 'local:check-in-id',
        type: PendingVisitOperationType.checkOut,
        targetType: VisitTargetType.project,
        targetExternalId: 'project-id',
        targetName: 'Obra Norte',
        occurredAtUtc: DateTime.utc(2026, 8, 7, 17),
        location: _location,
        dependsOnRequestId: 'check-in-id',
        createdAtUtc: DateTime.utc(2026, 8, 7, 17, 0, 1),
      ),
    ]);
    final visits = _SyncableVisitRepository();
    final repository = VisitSyncRepository(local, visits);

    final entries = await repository.getPending();
    await repository.synchronize();

    expect(entries.map((entry) => entry.type), [
      SyncQueueEntryType.projectVisitCheckIn,
      SyncQueueEntryType.projectVisitCheckOut,
    ]);
    expect(entries.last.dependsOnId, 'check-in-id');
    expect(visits.syncCalls, 1);
  });
}

const _location = LocationSample(
  latitude: -17.75,
  longitude: -63.18,
  accuracyMeters: 6,
);

class _PendingVisitStore implements VisitLocalStore {
  const _PendingVisitStore(this.operations);

  final List<PendingVisitOperation> operations;

  @override
  Future<List<PendingVisitOperation>> readPending() async => operations;

  @override
  Future<int> pendingCount() async => operations.length;

  @override
  Future<void> enqueue(
    PendingVisitOperation operation, {
    required CurrentVisit? current,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> markSynced(
    String requestId, {
    String? localVisitId,
    String? serverVisitId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<CurrentVisit?> readCurrent() {
    throw UnimplementedError();
  }

  @override
  Future<void> recordFailure(String requestId, String message) {
    throw UnimplementedError();
  }

  @override
  Future<String?> serverIdForLocalId(String localVisitId) {
    throw UnimplementedError();
  }

  @override
  Future<void> writeCurrent(CurrentVisit? visit) {
    throw UnimplementedError();
  }
}

class _SyncableVisitRepository implements VisitRepository {
  int syncCalls = 0;

  @override
  Future<void> syncPending() async => syncCalls += 1;

  @override
  Future<int> pendingCount() async => 0;

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
}
