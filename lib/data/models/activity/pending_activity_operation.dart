import 'dart:convert';

import '../common/utc_date_time.dart';

enum ActivityResourceType { customer, project }

enum PendingActivityOperationType { note, reminder, completeReminder }

class PendingActivityOperation {
  const PendingActivityOperation({
    required this.requestId,
    required this.resourceType,
    required this.resourceExternalId,
    required this.type,
    required this.eventAtUtc,
    required this.createdAtUtc,
    this.text,
    this.assignedToId,
    this.reminderExternalId,
    this.attemptCount = 0,
    this.lastError,
  });

  factory PendingActivityOperation.fromMap(Map<String, Object?> map) {
    final decoded = jsonDecode(map['payload'] as String);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid activity operation payload.');
    }
    return PendingActivityOperation(
      requestId: map['request_id'] as String,
      resourceType: ActivityResourceType.values.byName(
        map['resource_type'] as String,
      ),
      resourceExternalId: map['resource_external_id'] as String,
      type: PendingActivityOperationType.values.byName(
        map['operation_type'] as String,
      ),
      eventAtUtc: parseUtcDateTime(decoded['eventAtUtc']),
      createdAtUtc: parseUtcDateTime(map['created_at_utc']),
      text: decoded['text'] as String?,
      assignedToId: decoded['assignedToId'] as String?,
      reminderExternalId: decoded['reminderExternalId'] as String?,
      attemptCount: map['attempt_count'] as int? ?? 0,
      lastError: map['last_error'] as String?,
    );
  }

  final String requestId;
  final ActivityResourceType resourceType;
  final String resourceExternalId;
  final PendingActivityOperationType type;
  final DateTime eventAtUtc;
  final DateTime createdAtUtc;
  final String? text;
  final String? assignedToId;
  final String? reminderExternalId;
  final int attemptCount;
  final String? lastError;

  Map<String, Object?> toMap() => {
    'request_id': requestId,
    'resource_type': resourceType.name,
    'resource_external_id': resourceExternalId,
    'operation_type': type.name,
    'payload': jsonEncode({
      'eventAtUtc': eventAtUtc.toUtc().toIso8601String(),
      'text': text,
      'assignedToId': assignedToId,
      'reminderExternalId': reminderExternalId,
    }),
    'attempt_count': attemptCount,
    'last_error': lastError,
    'created_at_utc': createdAtUtc.toUtc().toIso8601String(),
  };
}
