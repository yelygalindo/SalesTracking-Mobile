import '../models/attachment/attachment_save_result.dart';
import '../models/attachment/attachment_source_file.dart';
import '../models/attachment/attachment_upload_options.dart';
import '../models/attachment/project_attachment.dart';

abstract interface class ProjectAttachmentRepository {
  Future<AttachmentUploadOptions> getOptions();

  Future<List<ProjectAttachment>> getAttachments(String projectExternalId);

  Future<AttachmentSaveResult> saveAttachments({
    required String projectExternalId,
    required List<AttachmentSourceFile> sources,
    required String attachmentType,
    String? visitExternalId,
    String? caption,
    bool isCover = false,
  });

  Future<int> pendingCount();

  Future<void> syncPending();
}
