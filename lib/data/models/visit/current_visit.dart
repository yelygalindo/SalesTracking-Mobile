import 'visit_target_type.dart';

class CurrentVisit {
  const CurrentVisit({
    required this.type,
    required this.externalId,
    required this.targetExternalId,
    required this.targetName,
    required this.checkInAtUtc,
    required this.latitude,
    required this.longitude,
    required this.note,
  });

  factory CurrentVisit.fromJson(Map<String, dynamic> json) => CurrentVisit(
    type: _type(json['type']),
    externalId: json['visitExternalId'] as String? ?? '',
    targetExternalId: json['targetExternalId'] as String? ?? '',
    targetName: json['targetName'] as String? ?? '',
    checkInAtUtc: _date(json['checkInAtUtc']),
    latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
    longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
    note: json['note'] as String?,
  );

  final VisitTargetType type;
  final String externalId;
  final String targetExternalId;
  final String targetName;
  final DateTime checkInAtUtc;
  final double latitude;
  final double longitude;
  final String? note;

  bool matches(VisitTargetType targetType, String targetId) =>
      type == targetType && targetExternalId == targetId;

  Map<String, dynamic> toJson() => {
    'type': type.apiValue,
    'visitExternalId': externalId,
    'targetExternalId': targetExternalId,
    'targetName': targetName,
    'checkInAtUtc': checkInAtUtc.toUtc().toIso8601String(),
    'latitude': latitude,
    'longitude': longitude,
    'note': note,
  };
}

VisitTargetType _type(Object? value) {
  final normalized = value?.toString().toLowerCase();
  return normalized == 'project'
      ? VisitTargetType.project
      : VisitTargetType.customer;
}

DateTime _date(Object? value) => value is String
    ? DateTime.tryParse(value)?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true)
    : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
