import 'package:urbantrack/data/models/attachment/attachment_save_result.dart';
import 'package:urbantrack/data/models/attachment/attachment_source_file.dart';
import 'package:urbantrack/data/models/attachment/attachment_upload_options.dart';
import 'package:urbantrack/data/models/attachment/pending_attachment_operation.dart';
import 'package:urbantrack/data/models/attachment/project_attachment.dart';
import 'package:urbantrack/data/models/visit/current_visit.dart';
import 'package:urbantrack/data/models/visit/pending_visit_operation.dart';
import 'package:urbantrack/data/repositories/attachment_local_store.dart';
import 'package:urbantrack/data/repositories/project_attachment_repository.dart';
import 'package:urbantrack/data/repositories/visit_local_store.dart';
import 'package:urbantrack/data/services/attachment_picker_service.dart';
import 'package:urbantrack/data/storage/attachment_file_store.dart';

class FakeAttachmentPickerService implements AttachmentPickerService {
  FakeAttachmentPickerService({
    this.cameraImage,
    this.galleryImages = const [],
    this.recoveredImages = const [],
  });

  final AttachmentSourceFile? cameraImage;
  final List<AttachmentSourceFile> galleryImages;
  final List<AttachmentSourceFile> recoveredImages;
  int cameraCalls = 0;
  int galleryCalls = 0;

  @override
  Future<List<AttachmentSourceFile>> recoverLostImages() async =>
      recoveredImages;

  @override
  Future<AttachmentSourceFile?> takePhoto() async {
    cameraCalls += 1;
    return cameraImage;
  }

  @override
  Future<List<AttachmentSourceFile>> pickFromGallery() async {
    galleryCalls += 1;
    return galleryImages;
  }
}

class MemoryAttachmentLocalStore implements AttachmentLocalStore {
  final List<PendingAttachmentOperation> operations = [];

  @override
  Future<void> enqueue(PendingAttachmentOperation operation) async {
    operations.add(operation);
  }

  @override
  Future<void> markSynced(String requestId) async {
    operations.removeWhere((operation) => operation.requestId == requestId);
  }

  @override
  Future<int> pendingCount() async => operations.length;

  @override
  Future<List<PendingAttachmentOperation>> readPending() async =>
      List.unmodifiable(operations);

  @override
  Future<void> recordFailure(String requestId, String message) async {}
}

class PassThroughAttachmentFileStore implements AttachmentFileStore {
  final List<AttachmentSourceFile> persisted = [];
  final List<String> deletedPaths = [];

  @override
  Future<AttachmentSourceFile> persist(AttachmentSourceFile source) async {
    persisted.add(source);
    return source;
  }

  @override
  Future<void> delete(String path) async => deletedPaths.add(path);
}

class RecordingAttachmentRemoteRepository
    implements ProjectAttachmentRepository {
  int saveCalls = 0;

  @override
  Future<AttachmentUploadOptions> getOptions() async =>
      const AttachmentUploadOptions(
        maxFileSizeBytes: 5 * 1024 * 1024,
        attachmentTypes: [
          AttachmentTypeOption(
            value: 'photo',
            label: 'Fotografía',
            description: 'Evidencia fotográfica',
          ),
        ],
        acceptedFormats: [
          AttachmentFormatOption(
            description: 'PNG',
            extensions: ['.png'],
            contentTypes: ['image/png'],
          ),
        ],
      );

  @override
  Future<List<ProjectAttachment>> getAttachments(
    String projectExternalId,
  ) async => const [];

  @override
  Future<AttachmentSaveResult> saveAttachments({
    required String projectExternalId,
    required List<AttachmentSourceFile> sources,
    required String attachmentType,
    String? visitExternalId,
    String? caption,
    bool isCover = false,
  }) async {
    saveCalls += 1;
    return AttachmentSaveResult(savedCount: sources.length, pendingCount: 0);
  }

  @override
  Future<int> pendingCount() async => 0;

  @override
  Future<void> syncPending() async {}
}

class NoopVisitLocalStore implements VisitLocalStore {
  @override
  Future<void> enqueue(
    PendingVisitOperation operation, {
    required CurrentVisit? current,
  }) async {}

  @override
  Future<void> markSynced(
    String requestId, {
    String? localVisitId,
    String? serverVisitId,
  }) async {}

  @override
  Future<int> pendingCount() async => 0;

  @override
  Future<CurrentVisit?> readCurrent() async => null;

  @override
  Future<List<PendingVisitOperation>> readPending() async => const [];

  @override
  Future<void> recordFailure(String requestId, String message) async {}

  @override
  Future<String?> serverIdForLocalId(String localVisitId) async => null;

  @override
  Future<void> writeCurrent(CurrentVisit? visit) async {}
}
