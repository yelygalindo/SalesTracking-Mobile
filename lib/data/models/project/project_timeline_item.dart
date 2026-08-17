import 'dart:convert';

import '../common/user_reference.dart';

class ProjectTimelineItem {
  const ProjectTimelineItem({
    required this.externalId,
    required this.eventTypeId,
    required this.eventTypeName,
    required this.title,
    required this.description,
    required this.occurredAtUtc,
    required this.createdBy,
    required this.relatedEntityType,
    required this.relatedEntityId,
    required this.metadataJson,
    required this.visitExternalId,
  });

  factory ProjectTimelineItem.fromJson(Map<String, dynamic> json) {
    final createdBy = json['createdBy'];
    return ProjectTimelineItem(
      externalId: json['externalId'] as String? ?? '',
      eventTypeId: json['eventTypeId'] as int? ?? 0,
      eventTypeName: json['eventTypeName'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      occurredAtUtc: _requiredDate(json['occurredAtUtc']),
      createdBy: createdBy is Map<String, dynamic>
          ? UserReference.fromJson(createdBy)
          : null,
      relatedEntityType: json['relatedEntityType'] as String?,
      relatedEntityId: json['relatedEntityId'] as int?,
      metadataJson: ProjectTimelineMetadata.fromValue(json['metadataJson']),
      visitExternalId: json['visitExternalId'] as String?,
    );
  }

  final String externalId;
  final int eventTypeId;
  final String eventTypeName;
  final String title;
  final String description;
  final DateTime occurredAtUtc;
  final UserReference? createdBy;
  final String? relatedEntityType;
  final int? relatedEntityId;
  final ProjectTimelineMetadata? metadataJson;
  final String? visitExternalId;

  Map<String, dynamic> toJson() => {
    'externalId': externalId,
    'eventTypeId': eventTypeId,
    'eventTypeName': eventTypeName,
    'title': title,
    'description': description,
    'occurredAtUtc': occurredAtUtc.toUtc().toIso8601String(),
    'createdBy': createdBy?.toJson(),
    'relatedEntityType': relatedEntityType,
    'relatedEntityId': relatedEntityId,
    'metadataJson': metadataJson?.toJson(),
    'visitExternalId': visitExternalId,
  };
}

class ProjectTimelineMetadata {
  const ProjectTimelineMetadata({
    required this.attachmentExternalId,
    required this.fileName,
    required this.attachmentType,
    required this.contentType,
    required this.sizeBytes,
    required this.visitExternalId,
    required this.downloadUrl,
    required this.downloadUrlExpiresAtUtc,
  });

  factory ProjectTimelineMetadata.fromJson(Map<String, dynamic> json) =>
      ProjectTimelineMetadata(
        attachmentExternalId: json['attachmentExternalId'] as String? ?? '',
        fileName: json['fileName'] as String? ?? '',
        attachmentType: json['attachmentType'] as String? ?? '',
        contentType: json['contentType'] as String? ?? '',
        sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
        visitExternalId: json['visitExternalId'] as String?,
        downloadUrl: json['downloadUrl'] as String?,
        downloadUrlExpiresAtUtc: _optionalDate(json['downloadUrlExpiresAtUtc']),
      );

  static ProjectTimelineMetadata? fromValue(Object? value) {
    Map<String, dynamic>? json;
    if (value is Map<String, dynamic>) {
      json = value;
    } else if (value is Map) {
      json = value.map((key, value) => MapEntry('$key', value));
    } else if (value is String && value.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map<String, dynamic>) {
          json = decoded;
        } else if (decoded is Map) {
          json = decoded.map((key, value) => MapEntry('$key', value));
        }
      } on FormatException {
        return null;
      }
    }
    return json == null ? null : ProjectTimelineMetadata.fromJson(json);
  }

  final String attachmentExternalId;
  final String fileName;
  final String attachmentType;
  final String contentType;
  final int sizeBytes;
  final String? visitExternalId;
  final String? downloadUrl;
  final DateTime? downloadUrlExpiresAtUtc;

  bool get isImage => contentType.toLowerCase().startsWith('image/');
  bool get hasDownloadUrl => downloadUrl?.trim().isNotEmpty == true;

  Map<String, dynamic> toJson() => {
    'attachmentExternalId': attachmentExternalId,
    'fileName': fileName,
    'attachmentType': attachmentType,
    'contentType': contentType,
    'sizeBytes': sizeBytes,
    'visitExternalId': visitExternalId,
    'downloadUrl': downloadUrl,
    'downloadUrlExpiresAtUtc': downloadUrlExpiresAtUtc
        ?.toUtc()
        .toIso8601String(),
  };
}

DateTime _requiredDate(Object? value) => value is String
    ? DateTime.tryParse(value)?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true)
    : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

DateTime? _optionalDate(Object? value) =>
    value is String ? DateTime.tryParse(value)?.toUtc() : null;
