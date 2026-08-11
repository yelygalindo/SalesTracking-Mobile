import 'project_timeline_item.dart';

class ProjectTimelinePage {
  const ProjectTimelinePage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalItems,
    required this.totalPages,
  });

  factory ProjectTimelinePage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final rawPagination = json['pagination'];
    final pagination = rawPagination is Map<String, dynamic>
        ? rawPagination
        : const <String, dynamic>{};
    return ProjectTimelinePage(
      items: rawItems is List
          ? rawItems
                .whereType<Map<String, dynamic>>()
                .map(ProjectTimelineItem.fromJson)
                .toList(growable: false)
          : const [],
      page: pagination['page'] as int? ?? 1,
      pageSize: pagination['pageSize'] as int? ?? 20,
      totalItems: pagination['totalItems'] as int? ?? 0,
      totalPages: pagination['totalPages'] as int? ?? 0,
    );
  }

  final List<ProjectTimelineItem> items;
  final int page;
  final int pageSize;
  final int totalItems;
  final int totalPages;

  Map<String, dynamic> toJson() => {
    'items': items.map((item) => item.toJson()).toList(growable: false),
    'pagination': {
      'page': page,
      'pageSize': pageSize,
      'totalItems': totalItems,
      'totalPages': totalPages,
    },
  };
}
