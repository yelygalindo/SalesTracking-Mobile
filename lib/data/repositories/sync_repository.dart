import '../models/sync/sync_queue_entry.dart';

abstract interface class SyncRepository {
  Future<List<SyncQueueEntry>> getPending();

  Future<void> synchronize();
}
