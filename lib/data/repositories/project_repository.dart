import '../models/project/project_detail.dart';
import '../models/project/project_input.dart';
import '../models/project/project_page.dart';

abstract interface class ProjectRepository {
  Future<ProjectPage> getProjects({
    String? status,
    String? customerId,
    String? sellerId,
    int page = 1,
    int pageSize = 20,
  });

  Future<ProjectDetail> getProject(String externalId);

  Future<ProjectDetail> createProject(
    ProjectInput input,
    String clientRequestId,
  );

  Future<void> updateProject(String externalId, ProjectInput input);

  Future<void> changeStatus(String externalId, int statusId);
}
