import 'package:flutter_test/flutter_test.dart';
import 'package:urbantrack/data/models/common/location_sample.dart';
import 'package:urbantrack/data/models/sync/sync_queue_entry.dart';
import 'package:urbantrack/data/models/workday/current_workday_response.dart';
import 'package:urbantrack/data/models/workday/pending_workday_operation.dart';
import 'package:urbantrack/data/models/workday/workday.dart';
import 'package:urbantrack/data/repositories/workday_local_store.dart';
import 'package:urbantrack/data/repositories/workday_repository.dart';
import 'package:urbantrack/data/repositories/workday_sync_repository.dart';

void main() {
  test('maps workday operations and delegates synchronization', () async {
    final local = _PendingLocalStore([
      PendingWorkdayOperation(
        requestId: 'start-id',
        localWorkdayId: 'local:start-id',
        type: PendingWorkdayOperationType.start,
        occurredAtUtc: DateTime.utc(2026, 8, 7, 15),
        location: _location,
        createdAtUtc: DateTime.utc(2026, 8, 7, 15, 0, 1),
      ),
      PendingWorkdayOperation(
        requestId: 'close-id',
        localWorkdayId: 'local:start-id',
        type: PendingWorkdayOperationType.close,
        occurredAtUtc: DateTime.utc(2026, 8, 7, 22),
        location: _location,
        dependsOnRequestId: 'start-id',
        createdAtUtc: DateTime.utc(2026, 8, 7, 22, 0, 1),
      ),
    ]);
    final workdays = _SyncableWorkdayRepository();
    final repository = WorkdaySyncRepository(local, workdays);

    final entries = await repository.getPending();
    await repository.synchronize();

    expect(entries.map((item) => item.type), [
      SyncQueueEntryType.workdayStart,
      SyncQueueEntryType.workdayClose,
    ]);
    expect(entries.last.dependsOnId, 'start-id');
    expect(workdays.syncCalls, 1);
  });
}

const _location = LocationSample(
  latitude: -12.0464,
  longitude: -77.0428,
  accuracyMeters: 7,
);

class _PendingLocalStore implements WorkdayLocalStore {
  _PendingLocalStore(this.operations);

  final List<PendingWorkdayOperation> operations;

  @override
  Future<List<PendingWorkdayOperation>> readPending() async => operations;

  @override
  Future<int> pendingCount() async => operations.length;

  @override
  Future<void> enqueue(
    PendingWorkdayOperation operation, {
    required Workday current,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> markSynced(
    String requestId, {
    String? localWorkdayId,
    String? serverWorkdayId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Workday?> readCurrent() {
    throw UnimplementedError();
  }

  @override
  Future<void> recordFailure(String requestId, String message) {
    throw UnimplementedError();
  }

  @override
  Future<String?> serverIdForLocalId(String localWorkdayId) {
    throw UnimplementedError();
  }

  @override
  Future<void> writeCurrent(Workday? workday) {
    throw UnimplementedError();
  }
}

class _SyncableWorkdayRepository implements WorkdayRepository {
  int syncCalls = 0;

  @override
  Future<void> syncPending() async => syncCalls += 1;

  @override
  Future<int> pendingCount() async => 0;

  @override
  Future<CurrentWorkdayResponse> getCurrent() {
    throw UnimplementedError();
  }

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
