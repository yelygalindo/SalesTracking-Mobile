import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

import '../models/attachment/attachment_source_file.dart';
import 'attachment_picker_service.dart';

class ImagePickerAttachmentService implements AttachmentPickerService {
  ImagePickerAttachmentService({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<List<AttachmentSourceFile>> recoverLostImages() async {
    final response = await _picker.retrieveLostData();
    final files = response.files;
    if (files == null) return const [];
    return Future.wait(files.map(_toSource));
  }

  @override
  Future<AttachmentSourceFile?> takePhoto() async {
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
      requestFullMetadata: false,
    );
    return image == null ? null : _toSource(image);
  }

  @override
  Future<List<AttachmentSourceFile>> pickFromGallery() async {
    final images = await _picker.pickMultiImage(
      imageQuality: 90,
      requestFullMetadata: false,
    );
    return Future.wait(images.map(_toSource));
  }

  Future<AttachmentSourceFile> _toSource(XFile image) async =>
      AttachmentSourceFile(
        path: image.path,
        fileName: image.name,
        contentType:
            image.mimeType ?? lookupMimeType(image.path) ?? 'image/jpeg',
        sizeBytes: await image.length(),
      );
}
