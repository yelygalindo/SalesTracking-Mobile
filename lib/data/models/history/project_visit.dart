import '../common/utc_date_time.dart';

class ProjectVisit {
  const ProjectVisit({
    required this.externalId,
    required this.projectExternalId,
    required this.projectName,
    required this.customerExternalId,
    required this.customerName,
    required this.visitedAtUtc,
    required this.latitude,
    required this.longitude,
    required this.notes,
    required this.checkOutAtUtc,
    required this.checkOutLatitude,
    required this.checkOutLongitude,
    required this.checkOutNote,
    required this.result,
    required this.sellerExternalId,
    required this.sellerName,
  });

  factory ProjectVisit.fromJson(Map<String, dynamic> json) => ProjectVisit(
    externalId: json['externalId'] as String? ?? '',
    projectExternalId: json['projectExternalId'] as String? ?? '',
    projectName: json['projectName'] as String? ?? '',
    customerExternalId: json['customerExternalId'] as String? ?? '',
    customerName: json['customerName'] as String? ?? '',
    visitedAtUtc: _requiredDate(json['visitedAtUtc']),
    latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
    longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
    notes: json['notes'] as String?,
    checkOutAtUtc: _optionalDate(json['checkOutAtUtc']),
    checkOutLatitude: (json['checkOutLatitude'] as num?)?.toDouble(),
    checkOutLongitude: (json['checkOutLongitude'] as num?)?.toDouble(),
    checkOutNote: json['checkOutNote'] as String?,
    result: json['result'] as String?,
    sellerExternalId: json['sellerExternalId'] as String? ?? '',
    sellerName: json['sellerName'] as String? ?? '',
  );

  final String externalId;
  final String projectExternalId;
  final String projectName;
  final String customerExternalId;
  final String customerName;
  final DateTime visitedAtUtc;
  final double latitude;
  final double longitude;
  final String? notes;
  final DateTime? checkOutAtUtc;
  final double? checkOutLatitude;
  final double? checkOutLongitude;
  final String? checkOutNote;
  final String? result;
  final String sellerExternalId;
  final String sellerName;

  bool get isOpen => checkOutAtUtc == null;
  Duration? get duration => checkOutAtUtc?.difference(visitedAtUtc);
}

DateTime _requiredDate(Object? value) => parseUtcDateTime(value);

DateTime? _optionalDate(Object? value) => tryParseUtcDateTime(value);
