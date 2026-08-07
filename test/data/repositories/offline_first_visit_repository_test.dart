import 'package:flutter_test/flutter_test.dart';
import 'package:urbantrack/data/models/common/location_sample.dart';
import 'package:urbantrack/data/models/visit/current_visit.dart';
import 'package:urbantrack/data/models/visit/pending_visit_operation.dart';
import 'package:urbantrack/data/models/visit/visit_target_type.dart';
import 'package:urbantrack/data/repositories/offline_first_visit_repository.dart';
import 'package:urbantrack/data/repositories/visit_local_store.dart';
import 'package:urbantrack/data/repositories/visit_repository.dart';
import 'package:urbantrack/data/services/api_exception.dart';
import 'package:urbantrack/data/services/network_status_service.dart';

void main() {
  test('queues offline check-in and check-out, then syncs in order', () async {
    final remote = _RecordingVisitRepository();
    final local = _MemoryVisitLocalStore();
    final network = _MutableNetworkStatusService(false);
    final createdTimes = [
      DateTime.utc(2026, 8, 7, 16, 0, 1),
      DateTime.utc(2026, 8, 7, 17, 0, 1),
    ];
    final repository = OfflineFirstVisitRepository(
      remote,
      local,
      network,
      now: () => createdTimes.removeAt(0),
    );

    final visit = await repository.checkIn(
      targetType: VisitTargetType.project,
      targetExternalId: 'project-id',
      targetName: 'Obra Norte',
      checkInAtUtc: DateTime.utc(2026, 8, 7, 16),
      location: _location,
      clientRequestId: 'check-in-id',
      note: 'Revisar avance',
    );
    await repository.checkOut(
      visit: visit,
      checkOutAtUtc: DateTime.utc(2026, 8, 7, 17),
      location: _location,
      clientRequestId: 'check-out-id',
      note: 'Segundo piso validado',
      result: 'Gestión realizada',
    );

    expect(visit.externalId, 'local:check-in-id');
    expect(await repository.getCurrent(), isNull);
    expect(await repository.pendingCount(), 2);
    expect(local.operations.last.dependsOnRequestId, 'check-in-id');

    network.connected = true;
    await repository.syncPending();

    expect(remote.calls, [
      'in:project:project-id:check-in-id',
      'out:server-visit-id:check-out-id',
    ]);
    expect(await repository.pendingCount(), 0);
  });

  test('queues an ambiguous transient check-in with the same id', () async {
    final local = _MemoryVisitLocalStore();
    final repository = OfflineFirstVisitRepository(
      _RecordingVisitRepository(
        checkInError: const ApiException(statusCode: 503, message: 'Temporal'),
      ),
      local,
      _MutableNetworkStatusService(true),
      now: () => DateTime.utc(2026, 8, 7, 16, 0, 1),
    );

    final visit = await repository.checkIn(
      targetType: VisitTargetType.customer,
      targetExternalId: 'customer-id',
      targetName: 'Cliente Norte',
      checkInAtUtc: DateTime.utc(2026, 8, 7, 16),
      location: _location,
      clientRequestId: 'stable-request-id',
    );

    expect(visit.externalId, 'local:stable-request-id');
    expect(local.operations.single.requestId, 'stable-request-id');
  });
}

const _location = LocationSample(
  latitude: -17.75,
  longitude: -63.18,
  accuracyMeters: 6,
);

class _MutableNetworkStatusService implements NetworkStatusService {
  _MutableNetworkStatusService(this.connected);

  bool connected;

  @override
  Future<bool> get isConnected async => connected;

  @override
  Stream<bool> get changes => const Stream.empty();
}

class _RecordingVisitRepository implements VisitRepository {
  _RecordingVisitRepository({this.checkInError});

  final ApiException? checkInError;
  final List<String> calls = [];

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
  }) async {
    calls.add('in:${targetType.name}:$targetExternalId:$clientRequestId');
    final error = checkInError;
    if (error != null) throw error;
    return CurrentVisit(
      type: targetType,
      externalId: 'server-visit-id',
      targetExternalId: targetExternalId,
      targetName: targetName,
      checkInAtUtc: checkInAtUtc,
      latitude: location.latitude,
      longitude: location.longitude,
      note: note,
    );
  }

  @override
  Future<void> checkOut({
    required CurrentVisit visit,
    required DateTime checkOutAtUtc,
    required LocationSample location,
    required String clientRequestId,
    String? note,
    String? result,
  }) async {
    calls.add('out:${visit.externalId}:$clientRequestId');
  }

  @override
  Future<int> pendingCount() async => 0;

  @override
  Future<void> syncPending() async {}
}

class _MemoryVisitLocalStore implements VisitLocalStore {
  CurrentVisit? current;
  final List<PendingVisitOperation> operations = [];
  final Map<String, String> mappings = {};

  @override
  Future<void> enqueue(
    PendingVisitOperation operation, {
    required CurrentVisit? current,
  }) async {
    if (!operations.any((item) => item.requestId == operation.requestId)) {
      operations.add(operation);
    }
    this.current = current;
  }

  @override
  Future<void> markSynced(
    String requestId, {
    String? localVisitId,
    String? serverVisitId,
  }) async {
    if (localVisitId != null && serverVisitId != null) {
      mappings[localVisitId] = serverVisitId;
    }
    operations.removeWhere((item) => item.requestId == requestId);
  }

  @override
  Future<int> pendingCount() async => operations.length;

  @override
  Future<CurrentVisit?> readCurrent() async => current;

  @override
  Future<List<PendingVisitOperation>> readPending() async =>
      List.unmodifiable(operations);

  @override
  Future<void> recordFailure(String requestId, String message) async {}

  @override
  Future<String?> serverIdForLocalId(String localVisitId) async =>
      mappings[localVisitId];

  @override
  Future<void> writeCurrent(CurrentVisit? visit) async => current = visit;
}
