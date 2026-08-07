class AttachmentSaveResult {
  const AttachmentSaveResult({
    required this.savedCount,
    required this.pendingCount,
  });

  final int savedCount;
  final int pendingCount;

  bool get hasPending => pendingCount > 0;
}
