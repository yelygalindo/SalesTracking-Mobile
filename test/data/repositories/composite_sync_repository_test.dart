import 'package:flutter_test/flutter_test.dart';
import 'package:urbantrack/data/models/sync/sync_queue_entry.dart';
import 'package:urbantrack/data/repositories/composite_sync_repository.dart';
import 'package:urbantrack/data/repositories/sync_repository.dart';
import 'package:urbantrack/data/services/api_exception.dart';

void main() {
  test('combines pending entries in chronological order', () async {
    final repository = CompositeSyncRepository([
      _FakeSyncRepository([_entry('later', DateTime.utc(2026, 8, 7, 18))]),
      _FakeSyncRepository([_entry('earlier', DateTime.utc(2026, 8, 7, 16))]),
    ]);

    final entries = await repository.getPending();

    expect(entries.map((entry) => entry.id), ['earlier', 'later']);
  });

  test('attempts every independent queue and then reports failure', () async {
    final failing = _FakeSyncRepository(
      const [],
      error: const ApiException(message: 'Temporal'),
    );
    final succeeding = _FakeSyncRepository(const []);
    final repository = CompositeSyncRepository([failing, succeeding]);

    await expectLater(repository.synchronize(), throwsA(isA<ApiException>()));

    expect(failing.syncCalls, 1);
    expect(succeeding.syncCalls, 1);
  });
}

SyncQueueEntry _entry(String id, DateTime createdAtUtc) => SyncQueueEntry(
  id: id,
  type: SyncQueueEntryType.customerCreate,
  occurredAtUtc: createdAtUtc,
  createdAtUtc: createdAtUtc,
  attemptCount: 0,
);

class _FakeSyncRepository implements SyncRepository {
  _FakeSyncRepository(this.entries, {this.error});

  final List<SyncQueueEntry> entries;
  final Object? error;
  int syncCalls = 0;

  @override
  Future<List<SyncQueueEntry>> getPending() async => entries;

  @override
  Future<void> synchronize() async {
    syncCalls += 1;
    final failure = error;
    if (failure != null) throw failure;
  }
}
