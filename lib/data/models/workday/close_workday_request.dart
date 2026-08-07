class CloseWorkdayRequest {
  const CloseWorkdayRequest({
    required this.endedAtUtc,
    required this.latitude,
    required this.longitude,
    required this.clientRequestId,
  });

  final DateTime endedAtUtc;
  final double latitude;
  final double longitude;
  final String clientRequestId;

  Map<String, dynamic> toJson() => {
    'endedAtUtc': endedAtUtc.toUtc().toIso8601String(),
    'latitude': latitude,
    'longitude': longitude,
    'clientRequestId': clientRequestId,
  };
}
