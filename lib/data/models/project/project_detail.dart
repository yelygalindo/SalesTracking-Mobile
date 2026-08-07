class ProjectDetail {
  const ProjectDetail({
    required this.id,
    required this.externalId,
    required this.name,
    required this.description,
    required this.customerExternalId,
    required this.customerName,
    required this.sellerExternalId,
    required this.sellerName,
    required this.status,
    required this.estimatedAmount,
    required this.startDateUtc,
    required this.expectedCloseDateUtc,
    required this.progressPercentage,
    required this.actualCloseDateUtc,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.createdAtUtc,
  });

  factory ProjectDetail.fromJson(Map<String, dynamic> json) => ProjectDetail(
    id: json['id'] as int? ?? 0,
    externalId: json['externalId'] as String? ?? '',
    name: json['name'] as String? ?? '',
    description: json['description'] as String? ?? '',
    customerExternalId: json['customerExternalId'] as String?,
    customerName: json['customerName'] as String? ?? '',
    sellerExternalId: json['sellerExternalId'] as String?,
    sellerName: json['sellerName'] as String? ?? '',
    status: json['status'] as String? ?? '',
    estimatedAmount: (json['estimatedAmount'] as num?)?.toDouble(),
    startDateUtc: _date(json['startDateUtc']),
    expectedCloseDateUtc: _date(json['expectedCloseDateUtc']),
    progressPercentage: (json['progressPercentage'] as num?)?.toDouble() ?? 0,
    actualCloseDateUtc: _date(json['actualCloseDateUtc']),
    address: json['address'] as String? ?? '',
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    createdAtUtc: _date(json['createdAtUtc']),
  );

  final int id;
  final String externalId;
  final String name;
  final String description;
  final String? customerExternalId;
  final String customerName;
  final String? sellerExternalId;
  final String sellerName;
  final String status;
  final double? estimatedAmount;
  final DateTime? startDateUtc;
  final DateTime? expectedCloseDateUtc;
  final double progressPercentage;
  final DateTime? actualCloseDateUtc;
  final String address;
  final double? latitude;
  final double? longitude;
  final DateTime? createdAtUtc;
}

DateTime? _date(Object? value) =>
    value is String ? DateTime.tryParse(value)?.toUtc() : null;
