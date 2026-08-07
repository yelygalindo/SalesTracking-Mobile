class ProjectAttachment {
  const ProjectAttachment({
    required this.externalId,
    required this.fileName,
    required this.contentType,
    required this.sizeBytes,
    required this.attachmentType,
    required this.caption,
    required this.isCover,
    required this.downloadUrl,
    required this.createdAtUtc,
    required this.visitExternalId,
  });

  factory ProjectAttachment.fromJson(Map<String, dynamic> json) =>
      ProjectAttachment(
        externalId: json['externalId'] as String? ?? '',
        fileName: json['fileName'] as String? ?? '',
        contentType: json['contentType'] as String? ?? '',
        sizeBytes: json['sizeBytes'] as int? ?? 0,
        attachmentType: json['attachmentType'] as String? ?? '',
        caption: json['caption'] as String?,
        isCover: json['isCover'] as bool? ?? false,
        downloadUrl: json['downloadUrl'] as String?,
        createdAtUtc: _date(json['createdAtUtc']),
        visitExternalId: json['visitExternalId'] as String?,
      );

  final String externalId;
  final String fileName;
  final String contentType;
  final int sizeBytes;
  final String attachmentType;
  final String? caption;
  final bool isCover;
  final String? downloadUrl;
  final DateTime? createdAtUtc;
  final String? visitExternalId;
}

DateTime? _date(Object? value) =>
    value is String ? DateTime.tryParse(value)?.toUtc() : null;
