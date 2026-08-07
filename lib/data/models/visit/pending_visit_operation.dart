import '../common/location_sample.dart';
import 'visit_target_type.dart';

enum PendingVisitOperationType { checkIn, checkOut }

class PendingVisitOperation {
  const PendingVisitOperation({
    required this.requestId,
    required this.localVisitId,
    required this.type,
    required this.targetType,
    required this.targetExternalId,
    required this.targetName,
    required this.occurredAtUtc,
    required this.location,
    required this.createdAtUtc,
    this.note,
    this.result,
    this.serverVisitId,
    this.dependsOnRequestId,
    this.attemptCount = 0,
    this.lastError,
  });

  factory PendingVisitOperation.fromMap(Map<String, Object?> map) =>
      PendingVisitOperation(
        requestId: map['request_id'] as String,
        localVisitId: map['local_visit_id'] as String,
        type: PendingVisitOperationType.values.byName(
          map['operation_type'] as String,
        ),
        targetType: VisitTargetType.values.byName(map['target_type'] as String),
        targetExternalId: map['target_external_id'] as String,
        targetName: map['target_name'] as String,
        occurredAtUtc: DateTime.parse(map['occurred_at_utc'] as String).toUtc(),
        location: LocationSample(
          latitude: (map['latitude'] as num).toDouble(),
          longitude: (map['longitude'] as num).toDouble(),
          accuracyMeters: (map['accuracy_meters'] as num).toDouble(),
        ),
        note: map['note'] as String?,
        result: map['result'] as String?,
        serverVisitId: map['server_visit_id'] as String?,
        dependsOnRequestId: map['depends_on_request_id'] as String?,
        attemptCount: map['attempt_count'] as int? ?? 0,
        lastError: map['last_error'] as String?,
        createdAtUtc: DateTime.parse(map['created_at_utc'] as String).toUtc(),
      );

  final String requestId;
  final String localVisitId;
  final PendingVisitOperationType type;
  final VisitTargetType targetType;
  final String targetExternalId;
  final String targetName;
  final DateTime occurredAtUtc;
  final LocationSample location;
  final String? note;
  final String? result;
  final String? serverVisitId;
  final String? dependsOnRequestId;
  final int attemptCount;
  final String? lastError;
  final DateTime createdAtUtc;

  Map<String, Object?> toMap() => {
    'request_id': requestId,
    'local_visit_id': localVisitId,
    'operation_type': type.name,
    'target_type': targetType.name,
    'target_external_id': targetExternalId,
    'target_name': targetName,
    'occurred_at_utc': occurredAtUtc.toUtc().toIso8601String(),
    'latitude': location.latitude,
    'longitude': location.longitude,
    'accuracy_meters': location.accuracyMeters,
    'note': note,
    'result': result,
    'server_visit_id': serverVisitId,
    'depends_on_request_id': dependsOnRequestId,
    'attempt_count': attemptCount,
    'last_error': lastError,
    'created_at_utc': createdAtUtc.toUtc().toIso8601String(),
  };
}
