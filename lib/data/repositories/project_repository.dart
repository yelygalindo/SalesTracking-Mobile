import '../models/project/project_detail.dart';
import '../models/project/project_input.dart';
import '../models/project/project_note.dart';
import '../models/project/project_page.dart';
import '../models/project/project_reminder.dart';
import '../models/project/project_status.dart';
import '../models/project/project_timeline_page.dart';
import '../models/common/resource_creation_result.dart';

abstract interface class ProjectRepository {
  Future<ProjectPage> getProjects({
    String? status,
    String? customerId,
    String? sellerId,
    int page = 1,
    int pageSize = 20,
  });

  Future<ProjectDetail> getProject(String externalId);

  Future<List<ProjectStatus>> getStatuses();

  Future<List<ProjectNote>> getNotes(String projectExternalId);

  Future<ResourceCreationResult> addNote(
    String projectExternalId, {
    required String content,
    required String clientRequestId,
    required DateTime occurredAtUtc,
  });

  Future<List<ProjectReminder>> getReminders(
    String projectExternalId, {
    bool? completed,
  });

  Future<ResourceCreationResult> addReminder(
    String projectExternalId, {
    required String text,
    required DateTime reminderAtUtc,
    String? assignedToId,
  });

  Future<void> completeReminder(
    String projectExternalId,
    String reminderExternalId,
  );

  Future<ProjectTimelinePage> getTimeline(
    String projectExternalId, {
    int page = 1,
    int pageSize = 50,
  });

  Future<ProjectDetail> createProject(
    ProjectInput input,
    String clientRequestId,
  );

  Future<void> updateProject(String externalId, ProjectInput input);

  Future<void> changeStatus(String externalId, int statusId);
}
