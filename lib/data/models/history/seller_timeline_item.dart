import '../common/utc_date_time.dart';

class SellerTimelineItem {
  const SellerTimelineItem({
    required this.externalId,
    required this.eventType,
    required this.resourceType,
    required this.resourceExternalId,
    required this.title,
    required this.description,
    required this.occurredAtUtc,
  });

  factory SellerTimelineItem.fromJson(Map<String, dynamic> json) {
    return SellerTimelineItem(
      externalId: json['externalId'] as String? ?? '',
      eventType: json['eventType'] as String? ?? '',
      resourceType: json['resourceType'] as String? ?? '',
      resourceExternalId: json['resourceExternalId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      occurredAtUtc: parseUtcDateTime(json['occurredAtUtc']),
    );
  }

  final String externalId;
  final String eventType;
  final String resourceType;
  final String resourceExternalId;
  final String title;
  final String description;
  final DateTime occurredAtUtc;
}
