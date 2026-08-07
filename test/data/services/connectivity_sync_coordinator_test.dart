import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:urbantrack/data/models/sync/sync_queue_entry.dart';
import 'package:urbantrack/data/repositories/sync_repository.dart';
import 'package:urbantrack/data/services/connectivity_sync_coordinator.dart';
import 'package:urbantrack/data/services/network_status_service.dart';

void main() {
  test('syncs automatically when connectivity returns', () async {
    final network = _ControlledNetworkStatusService();
    final repository = _SyncRecordingRepository();
    final refreshed = Completer<void>();
    final coordinator = ConnectivitySyncCoordinator(
      network,
      repository,
      onSynced: () async => refreshed.complete(),
    )..start();

    network.controller.add(true);
    await refreshed.future.timeout(const Duration(seconds: 1));

    expect(repository.syncCalls, 1);
    await coordinator.dispose();
    await network.controller.close();
  });
}

class _ControlledNetworkStatusService implements NetworkStatusService {
  final StreamController<bool> controller = StreamController<bool>();

  @override
  Future<bool> get isConnected async => true;

  @override
  Stream<bool> get changes => controller.stream;
}

class _SyncRecordingRepository implements SyncRepository {
  int syncCalls = 0;

  @override
  Future<List<SyncQueueEntry>> getPending() async => const [];

  @override
  Future<void> synchronize() async => syncCalls += 1;
}
