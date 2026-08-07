import 'seller_timeline_item.dart';

class SellerTimelinePage {
  const SellerTimelinePage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalItems,
    required this.totalPages,
  });

  factory SellerTimelinePage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final pagination = json['pagination'];
    final pageData = pagination is Map<String, dynamic>
        ? pagination
        : const <String, dynamic>{};
    return SellerTimelinePage(
      items: rawItems is List
          ? rawItems
                .whereType<Map<String, dynamic>>()
                .map(SellerTimelineItem.fromJson)
                .toList(growable: false)
          : const [],
      page: pageData['page'] as int? ?? 1,
      pageSize: pageData['pageSize'] as int? ?? 20,
      totalItems: pageData['totalItems'] as int? ?? 0,
      totalPages: pageData['totalPages'] as int? ?? 0,
    );
  }

  final List<SellerTimelineItem> items;
  final int page;
  final int pageSize;
  final int totalItems;
  final int totalPages;
}
