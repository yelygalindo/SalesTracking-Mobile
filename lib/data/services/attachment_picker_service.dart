import '../models/attachment/attachment_source_file.dart';

abstract interface class AttachmentPickerService {
  Future<List<AttachmentSourceFile>> recoverLostImages();

  Future<AttachmentSourceFile?> takePhoto();

  Future<List<AttachmentSourceFile>> pickFromGallery();
}
