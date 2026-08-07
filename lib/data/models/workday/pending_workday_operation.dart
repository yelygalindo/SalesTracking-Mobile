import '../common/location_sample.dart';

enum PendingWorkdayOperationType { start, close }

class PendingWorkdayOperation {
  const PendingWorkdayOperation({
    required this.requestId,
    required this.localWorkdayId,
    required this.type,
    required this.occurredAtUtc,
    required this.location,
    required this.createdAtUtc,
    this.note,
    this.serverWorkdayId,
    this.dependsOnRequestId,
    this.attemptCount = 0,
    this.lastError,
  });

  factory PendingWorkdayOperation.fromMap(Map<String, Object?> map) {
    final typeName = map['operation_type'];
    final occurredAt = map['occurred_at_utc'];
    final createdAt = map['created_at_utc'];
    final latitude = map['latitude'];
    final longitude = map['longitude'];
    if (typeName is! String ||
        occurredAt is! String ||
        createdAt is! String ||
        latitude is! num ||
        longitude is! num) {
      throw const FormatException('Invalid pending workday operation.');
    }

    return PendingWorkdayOperation(
      requestId: map['request_id'] as String,
      localWorkdayId: map['local_workday_id'] as String,
      type: PendingWorkdayOperationType.values.byName(typeName),
      occurredAtUtc: DateTime.parse(occurredAt).toUtc(),
      location: LocationSample(
        latitude: latitude.toDouble(),
        longitude: longitude.toDouble(),
        accuracyMeters: (map['accuracy_meters'] as num?)?.toDouble() ?? 0,
      ),
      note: map['note'] as String?,
      serverWorkdayId: map['server_workday_id'] as String?,
      dependsOnRequestId: map['depends_on_request_id'] as String?,
      attemptCount: map['attempt_count'] as int? ?? 0,
      lastError: map['last_error'] as String?,
      createdAtUtc: DateTime.parse(createdAt).toUtc(),
    );
  }

  final String requestId;
  final String localWorkdayId;
  final PendingWorkdayOperationType type;
  final DateTime occurredAtUtc;
  final LocationSample location;
  final String? note;
  final String? serverWorkdayId;
  final String? dependsOnRequestId;
  final int attemptCount;
  final String? lastError;
  final DateTime createdAtUtc;

  Map<String, Object?> toMap() => {
    'request_id': requestId,
    'local_workday_id': localWorkdayId,
    'operation_type': type.name,
    'occurred_at_utc': occurredAtUtc.toUtc().toIso8601String(),
    'latitude': location.latitude,
    'longitude': location.longitude,
    'accuracy_meters': location.accuracyMeters,
    'note': note,
    'server_workday_id': serverWorkdayId,
    'depends_on_request_id': dependsOnRequestId,
    'attempt_count': attemptCount,
    'last_error': lastError,
    'created_at_utc': createdAtUtc.toUtc().toIso8601String(),
  };
}
