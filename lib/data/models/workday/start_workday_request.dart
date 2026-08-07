class StartWorkdayRequest {
  const StartWorkdayRequest({
    required this.startedAtUtc,
    required this.latitude,
    required this.longitude,
    required this.clientRequestId,
    this.note,
  });

  final DateTime startedAtUtc;
  final double latitude;
  final double longitude;
  final String clientRequestId;
  final String? note;

  Map<String, dynamic> toJson() => {
    'startedAtUtc': startedAtUtc.toUtc().toIso8601String(),
    'latitude': latitude,
    'longitude': longitude,
    'note': note,
    'clientRequestId': clientRequestId,
  };
}
