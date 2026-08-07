import 'project_summary.dart';

class ProjectPage {
  const ProjectPage({
    required this.projects,
    required this.page,
    required this.pageSize,
    required this.totalItems,
    required this.totalPages,
  });

  factory ProjectPage.fromJson(Map<String, dynamic> json) {
    final items = json['items'];
    final pagination = json['pagination'];
    final pageData = pagination is Map<String, dynamic>
        ? pagination
        : const <String, dynamic>{};
    return ProjectPage(
      projects: items is List
          ? items
                .whereType<Map<String, dynamic>>()
                .map(ProjectSummary.fromJson)
                .toList(growable: false)
          : const [],
      page: pageData['page'] as int? ?? 1,
      pageSize: pageData['pageSize'] as int? ?? 20,
      totalItems: pageData['totalItems'] as int? ?? 0,
      totalPages: pageData['totalPages'] as int? ?? 0,
    );
  }

  final List<ProjectSummary> projects;
  final int page;
  final int pageSize;
  final int totalItems;
  final int totalPages;
}
