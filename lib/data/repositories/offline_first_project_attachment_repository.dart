import 'package:uuid/uuid.dart';

import '../models/attachment/attachment_save_result.dart';
import '../models/attachment/attachment_source_file.dart';
import '../models/attachment/attachment_upload_options.dart';
import '../models/attachment/pending_attachment_operation.dart';
import '../models/attachment/project_attachment.dart';
import '../services/api_exception.dart';
import '../services/network_status_service.dart';
import '../storage/attachment_file_store.dart';
import 'attachment_local_store.dart';
import 'project_attachment_repository.dart';
import 'visit_local_store.dart';

class OfflineFirstProjectAttachmentRepository
    implements ProjectAttachmentRepository {
  OfflineFirstProjectAttachmentRepository(
    this._remote,
    this._local,
    this._visitLocal,
    this._files,
    this._network, {
    String Function()? requestId,
    DateTime Function()? now,
  }) : _requestId = requestId ?? const Uuid().v4,
       _now = now ?? DateTime.now;

  final ProjectAttachmentRepository _remote;
  final AttachmentLocalStore _local;
  final VisitLocalStore _visitLocal;
  final AttachmentFileStore _files;
  final NetworkStatusService _network;
  final String Function() _requestId;
  final DateTime Function() _now;

  Future<void>? _activeSync;

  @override
  Future<AttachmentUploadOptions> getOptions() => _remote.getOptions();

  @override
  Future<List<ProjectAttachment>> getAttachments(String projectExternalId) =>
      _remote.getAttachments(projectExternalId);

  @override
  Future<int> pendingCount() => _local.pendingCount();

  @override
  Future<AttachmentSaveResult> saveAttachments({
    required String projectExternalId,
    required List<AttachmentSourceFile> sources,
    required String attachmentType,
    String? visitExternalId,
    String? caption,
    bool isCover = false,
  }) async {
    var saved = 0;
    for (final source in sources) {
      final durable = await _files.persist(source);
      await _local.enqueue(
        PendingAttachmentOperation(
          requestId: _requestId(),
          projectExternalId: projectExternalId,
          visitExternalId: visitExternalId,
          source: durable,
          attachmentType: attachmentType,
          caption: caption?.trim().isEmpty == true ? null : caption?.trim(),
          isCover: isCover && saved == 0,
          createdAtUtc: _now().toUtc(),
        ),
      );
      saved += 1;
    }

    if (await _network.isConnected) {
      try {
        await syncPending();
      } on ApiException {
        // Files remain durable and visible in the synchronization queue.
      }
    }
    return AttachmentSaveResult(
      savedCount: saved,
      pendingCount: await _local.pendingCount(),
    );
  }

  @override
  Future<void> syncPending() {
    final active = _activeSync;
    if (active != null) return active;
    late final Future<void> current;
    current = _syncPendingInternal().whenComplete(() {
      if (identical(_activeSync, current)) _activeSync = null;
    });
    _activeSync = current;
    return current;
  }

  Future<void> _syncPendingInternal() async {
    if (!await _network.isConnected) return;
    final operations = await _local.readPending();
    for (final operation in operations) {
      try {
        final resolvedVisitId = await _resolvedVisitId(
          operation.visitExternalId,
        );
        final remoteItems = await _remote.getAttachments(
          operation.projectExternalId,
        );
        final alreadyUploaded = remoteItems.any(
          (item) =>
              item.fileName == operation.source.fileName &&
              item.sizeBytes == operation.source.sizeBytes &&
              item.visitExternalId == resolvedVisitId,
        );
        if (!alreadyUploaded) {
          await _remote.saveAttachments(
            projectExternalId: operation.projectExternalId,
            sources: [operation.source],
            attachmentType: operation.attachmentType,
            visitExternalId: resolvedVisitId,
            caption: operation.caption,
            isCover: operation.isCover,
          );
        }
        await _local.markSynced(operation.requestId);
        await _files.delete(operation.source.path);
      } on ApiException catch (error) {
        await _local.recordFailure(operation.requestId, error.message);
        rethrow;
      } catch (error) {
        await _local.recordFailure(operation.requestId, error.toString());
        rethrow;
      }
    }
  }

  Future<String?> _resolvedVisitId(String? visitExternalId) async {
    if (visitExternalId == null || !visitExternalId.startsWith('local:')) {
      return visitExternalId;
    }
    final serverId = await _visitLocal.serverIdForLocalId(visitExternalId);
    if (serverId == null || serverId.isEmpty) {
      throw const ApiException(
        message: 'La visita aún no se ha sincronizado para cargar sus fotos.',
      );
    }
    return serverId;
  }
}
