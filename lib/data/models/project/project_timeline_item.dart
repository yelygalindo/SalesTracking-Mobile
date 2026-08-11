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
      metadataJson: json['metadataJson'] as String?,
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
  final String? metadataJson;
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
    'metadataJson': metadataJson,
    'visitExternalId': visitExternalId,
  };
}

DateTime _requiredDate(Object? value) => value is String
    ? DateTime.tryParse(value)?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true)
    : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
