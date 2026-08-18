import '../common/utc_date_time.dart';

class Workday {
  const Workday({
    required this.externalId,
    required this.status,
    required this.startedAtUtc,
    required this.startedReceivedAtUtc,
    required this.startLatitude,
    required this.startLongitude,
    this.note,
    this.endedAtUtc,
    this.endedReceivedAtUtc,
    this.endLatitude,
    this.endLongitude,
  });

  factory Workday.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'startedAtUtc': String startedAtUtc,
        'startedReceivedAtUtc': String startedReceivedAtUtc,
        'startLatitude': num startLatitude,
        'startLongitude': num startLongitude,
      } =>
        Workday(
          externalId: json['id'] as String?,
          status: json['status'] as String? ?? 'open',
          startedAtUtc: parseUtcDateTime(startedAtUtc),
          startedReceivedAtUtc: parseUtcDateTime(startedReceivedAtUtc),
          startLatitude: startLatitude.toDouble(),
          startLongitude: startLongitude.toDouble(),
          note: json['note'] as String?,
          endedAtUtc: _optionalDate(json['endedAtUtc']),
          endedReceivedAtUtc: _optionalDate(json['endedReceivedAtUtc']),
          endLatitude: (json['endLatitude'] as num?)?.toDouble(),
          endLongitude: (json['endLongitude'] as num?)?.toDouble(),
        ),
      _ => throw const FormatException('Invalid workday.'),
    };
  }

  final String? externalId;
  final String status;
  final DateTime startedAtUtc;
  final DateTime startedReceivedAtUtc;
  final double startLatitude;
  final double startLongitude;
  final String? note;
  final DateTime? endedAtUtc;
  final DateTime? endedReceivedAtUtc;
  final double? endLatitude;
  final double? endLongitude;

  bool get isOpen => endedAtUtc == null;

  Map<String, dynamic> toJson() => {
    'id': externalId,
    'status': status,
    'startedAtUtc': startedAtUtc.toUtc().toIso8601String(),
    'startedReceivedAtUtc': startedReceivedAtUtc.toUtc().toIso8601String(),
    'startLatitude': startLatitude,
    'startLongitude': startLongitude,
    'note': note,
    'endedAtUtc': endedAtUtc?.toUtc().toIso8601String(),
    'endedReceivedAtUtc': endedReceivedAtUtc?.toUtc().toIso8601String(),
    'endLatitude': endLatitude,
    'endLongitude': endLongitude,
  };
}

DateTime? _optionalDate(Object? value) => tryParseUtcDateTime(value);
