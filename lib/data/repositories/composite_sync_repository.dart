import '../models/sync/sync_queue_entry.dart';
import 'sync_repository.dart';

class CompositeSyncRepository implements SyncRepository {
  const CompositeSyncRepository(this._repositories);

  final List<SyncRepository> _repositories;

  @override
  Future<List<SyncQueueEntry>> getPending() async {
    final groups = await Future.wait(
      _repositories.map((repository) => repository.getPending()),
    );
    final entries = groups.expand((group) => group).toList();
    entries.sort(
      (left, right) => left.createdAtUtc.compareTo(right.createdAtUtc),
    );
    return List.unmodifiable(entries);
  }

  @override
  Future<void> synchronize() async {
    Object? firstError;
    StackTrace? firstStackTrace;
    for (final repository in _repositories) {
      try {
        await repository.synchronize();
      } catch (error, stackTrace) {
        firstError ??= error;
        firstStackTrace ??= stackTrace;
      }
    }
    if (firstError != null) {
      Error.throwWithStackTrace(firstError, firstStackTrace!);
    }
  }
}
