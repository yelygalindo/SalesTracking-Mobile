import 'attachment_source_file.dart';

class PendingAttachmentOperation {
  const PendingAttachmentOperation({
    required this.requestId,
    required this.projectExternalId,
    required this.source,
    required this.attachmentType,
    required this.isCover,
    required this.createdAtUtc,
    this.visitExternalId,
    this.caption,
    this.attemptCount = 0,
    this.lastError,
  });

  factory PendingAttachmentOperation.fromMap(Map<String, Object?> map) =>
      PendingAttachmentOperation(
        requestId: map['request_id'] as String,
        projectExternalId: map['project_external_id'] as String,
        visitExternalId: map['visit_external_id'] as String?,
        source: AttachmentSourceFile(
          path: map['file_path'] as String,
          fileName: map['file_name'] as String,
          contentType: map['content_type'] as String,
          sizeBytes: map['size_bytes'] as int,
        ),
        attachmentType: map['attachment_type'] as String,
        caption: map['caption'] as String?,
        isCover: (map['is_cover'] as int? ?? 0) == 1,
        attemptCount: map['attempt_count'] as int? ?? 0,
        lastError: map['last_error'] as String?,
        createdAtUtc: DateTime.parse(map['created_at_utc'] as String).toUtc(),
      );

  final String requestId;
  final String projectExternalId;
  final String? visitExternalId;
  final AttachmentSourceFile source;
  final String attachmentType;
  final String? caption;
  final bool isCover;
  final int attemptCount;
  final String? lastError;
  final DateTime createdAtUtc;

  Map<String, Object?> toMap() => {
    'request_id': requestId,
    'project_external_id': projectExternalId,
    'visit_external_id': visitExternalId,
    'file_path': source.path,
    'file_name': source.fileName,
    'content_type': source.contentType,
    'size_bytes': source.sizeBytes,
    'attachment_type': attachmentType,
    'caption': caption,
    'is_cover': isCover ? 1 : 0,
    'attempt_count': attemptCount,
    'last_error': lastError,
    'created_at_utc': createdAtUtc.toUtc().toIso8601String(),
  };
}
