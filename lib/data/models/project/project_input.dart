class ProjectInput {
  const ProjectInput({
    required this.name,
    required this.description,
    required this.customerExternalId,
    required this.sellerExternalId,
    required this.estimatedAmount,
    required this.startDateUtc,
    required this.expectedCloseDateUtc,
    required this.progressPercentage,
    required this.actualCloseDateUtc,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.expectedUpdatedAtUtc,
    this.expectedUpdatedAtUtcToken,
  });

  final String name;
  final String description;
  final String? customerExternalId;
  final String? sellerExternalId;
  final double? estimatedAmount;
  final DateTime? startDateUtc;
  final DateTime? expectedCloseDateUtc;
  final double? progressPercentage;
  final DateTime? actualCloseDateUtc;
  final String address;
  final double? latitude;
  final double? longitude;
  final DateTime? expectedUpdatedAtUtc;
  final String? expectedUpdatedAtUtcToken;

  Map<String, dynamic> toJson() => {
    'name': name.trim(),
    'description': description.trim(),
    'customerExternalId': customerExternalId,
    'sellerExternalId': sellerExternalId,
    'estimatedAmount': estimatedAmount,
    'startDateUtc': startDateUtc?.toUtc().toIso8601String(),
    'expectedCloseDateUtc': expectedCloseDateUtc?.toUtc().toIso8601String(),
    'progressPercentage': progressPercentage,
    'actualCloseDateUtc': actualCloseDateUtc?.toUtc().toIso8601String(),
    'address': address.trim(),
    'latitude': latitude,
    'longitude': longitude,
    'expectedUpdatedAtUtc':
        expectedUpdatedAtUtcToken ??
        expectedUpdatedAtUtc?.toUtc().toIso8601String(),
  };

  Map<String, dynamic> toCreateJson(String clientRequestId) => {
    'clientRequestId': clientRequestId,
    ...toJson()..remove('expectedUpdatedAtUtc'),
  };
}
