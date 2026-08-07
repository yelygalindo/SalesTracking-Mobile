import 'package:flutter_test/flutter_test.dart';
import 'package:urbantrack/data/models/attachment/attachment_save_result.dart';
import 'package:urbantrack/data/models/attachment/attachment_source_file.dart';
import 'package:urbantrack/data/models/attachment/attachment_upload_options.dart';
import 'package:urbantrack/data/models/attachment/pending_attachment_operation.dart';
import 'package:urbantrack/data/models/attachment/project_attachment.dart';
import 'package:urbantrack/data/models/visit/current_visit.dart';
import 'package:urbantrack/data/models/visit/pending_visit_operation.dart';
import 'package:urbantrack/data/repositories/attachment_local_store.dart';
import 'package:urbantrack/data/repositories/offline_first_project_attachment_repository.dart';
import 'package:urbantrack/data/repositories/project_attachment_repository.dart';
import 'package:urbantrack/data/repositories/visit_local_store.dart';
import 'package:urbantrack/data/services/network_status_service.dart';
import 'package:urbantrack/data/storage/attachment_file_store.dart';

void main() {
  test(
    'stores a photo offline and resolves its local visit before upload',
    () async {
      final remote = _RecordingAttachmentRepository();
      final local = _MemoryAttachmentLocalStore();
      final files = _MemoryAttachmentFileStore();
      final network = _MutableNetworkStatusService(false);
      final repository = OfflineFirstProjectAttachmentRepository(
        remote,
        local,
        _MappedVisitLocalStore(),
        files,
        network,
        requestId: () => 'photo-request-id',
        now: () => DateTime.utc(2026, 8, 7, 17),
      );

      final result = await repository.saveAttachments(
        projectExternalId: 'project-id',
        visitExternalId: 'local:check-in-id',
        sources: const [_source],
        attachmentType: 'photo',
        caption: 'Fachada',
      );

      expect(result.savedCount, 1);
      expect(result.pendingCount, 1);
      expect(local.operations.single.source.fileName, 'durable-photo.jpg');

      network.connected = true;
      await repository.syncPending();

      expect(remote.savedVisitId, 'server-visit-id');
      expect(remote.savedSources.single.fileName, 'durable-photo.jpg');
      expect(await repository.pendingCount(), 0);
      expect(files.deletedPaths, ['/durable/durable-photo.jpg']);
    },
  );

  test('reconciles an already uploaded photo without duplicating it', () async {
    final remote = _RecordingAttachmentRepository(
      attachments: [
        ProjectAttachment(
          externalId: 'attachment-id',
          fileName: 'durable-photo.jpg',
          contentType: 'image/jpeg',
          sizeBytes: 4,
          attachmentType: 'photo',
          caption: null,
          isCover: false,
          downloadUrl: null,
          createdAtUtc: DateTime.utc(2026, 8, 7, 17),
          visitExternalId: 'server-visit-id',
        ),
      ],
    );
    final local = _MemoryAttachmentLocalStore()
      ..operations.add(
        PendingAttachmentOperation(
          requestId: 'photo-request-id',
          projectExternalId: 'project-id',
          visitExternalId: 'local:check-in-id',
          source: const AttachmentSourceFile(
            path: '/durable/durable-photo.jpg',
            fileName: 'durable-photo.jpg',
            contentType: 'image/jpeg',
            sizeBytes: 4,
          ),
          attachmentType: 'photo',
          isCover: false,
          createdAtUtc: DateTime.utc(2026, 8, 7, 17),
        ),
      );
    final repository = OfflineFirstProjectAttachmentRepository(
      remote,
      local,
      _MappedVisitLocalStore(),
      _MemoryAttachmentFileStore(),
      _MutableNetworkStatusService(true),
    );

    await repository.syncPending();

    expect(remote.saveCalls, 0);
    expect(await repository.pendingCount(), 0);
  });
}

const _source = AttachmentSourceFile(
  path: '/cache/photo.jpg',
  fileName: 'photo.jpg',
  contentType: 'image/jpeg',
  sizeBytes: 4,
);

class _MutableNetworkStatusService implements NetworkStatusService {
  _MutableNetworkStatusService(this.connected);
  bool connected;

  @override
  Future<bool> get isConnected async => connected;

  @override
  Stream<bool> get changes => const Stream.empty();
}

class _MemoryAttachmentFileStore implements AttachmentFileStore {
  final List<String> deletedPaths = [];

  @override
  Future<AttachmentSourceFile> persist(AttachmentSourceFile source) async =>
      const AttachmentSourceFile(
        path: '/durable/durable-photo.jpg',
        fileName: 'durable-photo.jpg',
        contentType: 'image/jpeg',
        sizeBytes: 4,
      );

  @override
  Future<void> delete(String path) async => deletedPaths.add(path);
}

class _MemoryAttachmentLocalStore implements AttachmentLocalStore {
  final List<PendingAttachmentOperation> operations = [];

  @override
  Future<void> enqueue(PendingAttachmentOperation operation) async {
    operations.add(operation);
  }

  @override
  Future<void> markSynced(String requestId) async {
    operations.removeWhere((item) => item.requestId == requestId);
  }

  @override
  Future<int> pendingCount() async => operations.length;

  @override
  Future<List<PendingAttachmentOperation>> readPending() async =>
      List.unmodifiable(operations);

  @override
  Future<void> recordFailure(String requestId, String message) async {}
}

class _RecordingAttachmentRepository implements ProjectAttachmentRepository {
  _RecordingAttachmentRepository({this.attachments = const []});

  final List<ProjectAttachment> attachments;
  int saveCalls = 0;
  String? savedVisitId;
  List<AttachmentSourceFile> savedSources = const [];

  @override
  Future<List<ProjectAttachment>> getAttachments(
    String projectExternalId,
  ) async => attachments;

  @override
  Future<AttachmentUploadOptions> getOptions() async =>
      const AttachmentUploadOptions(
        maxFileSizeBytes: 0,
        attachmentTypes: [],
        acceptedFormats: [],
      );

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
    savedVisitId = visitExternalId;
    savedSources = sources;
    return AttachmentSaveResult(savedCount: sources.length, pendingCount: 0);
  }

  @override
  Future<int> pendingCount() async => 0;

  @override
  Future<void> syncPending() async {}
}

class _MappedVisitLocalStore implements VisitLocalStore {
  @override
  Future<String?> serverIdForLocalId(String localVisitId) async =>
      'server-visit-id';

  @override
  Future<CurrentVisit?> readCurrent() async => null;

  @override
  Future<List<PendingVisitOperation>> readPending() async => const [];

  @override
  Future<int> pendingCount() async => 0;

  @override
  Future<void> enqueue(
    PendingVisitOperation operation, {
    required CurrentVisit? current,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> markSynced(
    String requestId, {
    String? localVisitId,
    String? serverVisitId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> recordFailure(String requestId, String message) {
    throw UnimplementedError();
  }

  @override
  Future<void> writeCurrent(CurrentVisit? visit) {
    throw UnimplementedError();
  }
}
