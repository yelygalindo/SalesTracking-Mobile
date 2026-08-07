import 'package:flutter_test/flutter_test.dart';
import 'package:urbantrack/data/models/sync/sync_queue_entry.dart';
import 'package:urbantrack/data/repositories/sync_repository.dart';
import 'package:urbantrack/data/services/network_status_service.dart';
import 'package:urbantrack/ui/sync/sync_view_model.dart';

void main() {
  test('loads pending items and synchronizes them while connected', () async {
    final repository = _MemorySyncRepository([_entry]);
    final viewModel = SyncViewModel(
      repository,
      const _FixedNetworkStatusService(true),
      now: () => DateTime.utc(2026, 8, 7, 22, 5),
    );

    await viewModel.initialize();
    expect(viewModel.items, hasLength(1));
    expect(viewModel.connected, isTrue);

    expect(await viewModel.synchronize(), isTrue);
    expect(repository.syncCalls, 1);
    expect(viewModel.items, isEmpty);
    expect(viewModel.lastAttemptAt, DateTime.utc(2026, 8, 7, 22, 5));
  });

  test('keeps items and explains when a manual retry is offline', () async {
    final repository = _MemorySyncRepository([_entry]);
    final viewModel = SyncViewModel(
      repository,
      const _FixedNetworkStatusService(false),
    );

    await viewModel.initialize();

    expect(await viewModel.synchronize(), isFalse);
    expect(repository.syncCalls, 0);
    expect(viewModel.items, hasLength(1));
    expect(viewModel.errorMessage, contains('permanecen guardados'));
  });
}

final _entry = SyncQueueEntry(
  id: 'start-id',
  type: SyncQueueEntryType.workdayStart,
  occurredAtUtc: DateTime.utc(2026, 8, 7, 15),
  createdAtUtc: DateTime.utc(2026, 8, 7, 15, 0, 1),
  attemptCount: 0,
);

class _MemorySyncRepository implements SyncRepository {
  _MemorySyncRepository(List<SyncQueueEntry> items) : _items = [...items];

  List<SyncQueueEntry> _items;
  int syncCalls = 0;

  @override
  Future<List<SyncQueueEntry>> getPending() async => List.unmodifiable(_items);

  @override
  Future<void> synchronize() async {
    syncCalls += 1;
    _items = [];
  }
}

class _FixedNetworkStatusService implements NetworkStatusService {
  const _FixedNetworkStatusService(this.connected);

  final bool connected;

  @override
  Future<bool> get isConnected async => connected;

  @override
  Stream<bool> get changes => const Stream.empty();
}
