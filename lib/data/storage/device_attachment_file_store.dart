import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/attachment/attachment_source_file.dart';
import 'attachment_file_store.dart';

class DeviceAttachmentFileStore implements AttachmentFileStore {
  const DeviceAttachmentFileStore();

  @override
  Future<AttachmentSourceFile> persist(AttachmentSourceFile source) async {
    final root = await getApplicationDocumentsDirectory();
    final directory = Directory(path.join(root.path, 'pending_attachments'));
    await directory.create(recursive: true);
    final extension = path.extension(source.fileName).isEmpty
        ? _extensionFor(source.contentType)
        : path.extension(source.fileName).toLowerCase();
    final fileName = '${const Uuid().v4()}$extension';
    final destination = path.join(directory.path, fileName);
    await File(source.path).copy(destination);
    return AttachmentSourceFile(
      path: destination,
      fileName: fileName,
      contentType: source.contentType,
      sizeBytes: await File(destination).length(),
    );
  }

  @override
  Future<void> delete(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) await file.delete();
  }

  String _extensionFor(String contentType) => switch (contentType) {
    'image/png' => '.png',
    'image/heic' || 'image/heif' => '.heic',
    _ => '.jpg',
  };
}
