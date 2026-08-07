import '../models/attachment/attachment_source_file.dart';

abstract interface class AttachmentFileStore {
  Future<AttachmentSourceFile> persist(AttachmentSourceFile source);

  Future<void> delete(String path);
}
