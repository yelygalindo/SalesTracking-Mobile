import 'package:uuid/uuid.dart';

import '../models/attachment/attachment_save_result.dart';
import '../models/attachment/attachment_source_file.dart';
import '../models/attachment/attachment_upload_options.dart';
import '../models/attachment/project_attachment.dart';
import '../models/auth/auth_session.dart';
import '../services/api_exception.dart';
import '../services/project_attachment_service.dart';
import 'auth_repository.dart';
import 'project_attachment_repository.dart';

class RemoteProjectAttachmentRepository implements ProjectAttachmentRepository {
  const RemoteProjectAttachmentRepository(this._service, this._authRepository);

  final ProjectAttachmentService _service;
  final AuthRepository _authRepository;

  @override
  Future<AttachmentUploadOptions> getOptions() async {
    final session = await _session();
    return _service.getOptions(session.accessToken);
  }

  @override
  Future<List<ProjectAttachment>> getAttachments(
    String projectExternalId,
  ) async {
    final session = await _session();
    return _service.getAttachments(session.accessToken, projectExternalId);
  }

  @override
  Future<AttachmentSaveResult> saveAttachments({
    required String projectExternalId,
    required List<AttachmentSourceFile> sources,
    required String attachmentType,
    String? visitExternalId,
    String? caption,
    bool isCover = false,
    String? clientRequestId,
    DateTime? occurredAtUtc,
  }) async {
    if (clientRequestId != null && sources.length != 1) {
      throw ArgumentError(
        'clientRequestId solo puede reutilizarse para un adjunto individual.',
      );
    }
    final session = await _session();
    for (final source in sources) {
      await _service.upload(
        session.accessToken,
        projectExternalId: projectExternalId,
        source: source,
        attachmentType: attachmentType,
        clientRequestId: clientRequestId ?? const Uuid().v4(),
        occurredAtUtc: occurredAtUtc ?? DateTime.now().toUtc(),
        visitExternalId: visitExternalId,
        caption: caption,
        isCover: isCover,
      );
    }
    return AttachmentSaveResult(savedCount: sources.length, pendingCount: 0);
  }

  @override
  Future<int> pendingCount() async => 0;

  @override
  Future<void> syncPending() async {}

  Future<AuthSession> _session() async {
    final session = await _authRepository.restoreSession();
    if (session == null) {
      throw const ApiException(
        statusCode: 401,
        message: 'Tu sesión expiró. Inicia sesión nuevamente.',
      );
    }
    return session;
  }
}
