enum SyncQueueEntryType { workdayStart, workdayClose, customerCreate }

class SyncQueueEntry {
  const SyncQueueEntry({
    required this.id,
    required this.type,
    required this.occurredAtUtc,
    required this.createdAtUtc,
    required this.attemptCount,
    this.dependsOnId,
    this.lastError,
  });

  final String id;
  final SyncQueueEntryType type;
  final DateTime occurredAtUtc;
  final DateTime createdAtUtc;
  final String? dependsOnId;
  final int attemptCount;
  final String? lastError;
}
