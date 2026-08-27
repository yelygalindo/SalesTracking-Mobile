import '../models/attachment/project_attachment.dart';
import '../models/history/project_visit.dart';
import '../models/history/seller_timeline_item.dart';
import '../models/history/seller_timeline_page.dart';

abstract interface class HistoryRepository {
  Future<SellerTimelinePage> getMyTimeline({
    DateTime? from,
    DateTime? to,
    int page = 1,
    int pageSize = 30,
  });

  Future<List<ProjectVisit>> getProjectVisits(
    String projectExternalId, {
    String? sellerExternalId,
    DateTime? from,
    DateTime? to,
  });

  Future<List<SellerTimelineItem>> getCustomerTimeline(
    String customerExternalId,
  );

  Future<List<ProjectVisit>> getCustomerVisits(String customerExternalId);

  Future<List<ProjectAttachment>> getVisitAttachments(String visitExternalId);
}
