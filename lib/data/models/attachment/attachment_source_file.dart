class AttachmentSourceFile {
  const AttachmentSourceFile({
    required this.path,
    required this.fileName,
    required this.contentType,
    required this.sizeBytes,
  });

  final String path;
  final String fileName;
  final String contentType;
  final int sizeBytes;
}
