import '../models/project/project_detail.dart';
import '../models/project/project_page.dart';
import '../models/project/project_summary.dart';

abstract interface class ProjectLocalStore {
  Future<void> cacheProjects(List<ProjectSummary> projects);

  Future<ProjectPage> readProjects({
    String? status,
    String? customerId,
    String? sellerId,
    int page = 1,
    int pageSize = 20,
  });

  Future<void> cacheDetail(ProjectDetail project);

  Future<ProjectDetail?> readDetail(String externalId);
}
