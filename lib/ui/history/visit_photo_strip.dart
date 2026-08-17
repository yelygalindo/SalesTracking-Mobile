import 'package:flutter/material.dart';

import '../../data/models/attachment/project_attachment.dart';

typedef VisitPhotoImageProvider =
    ImageProvider<Object> Function(ProjectAttachment attachment);

class VisitPhotoStrip extends StatelessWidget {
  const VisitPhotoStrip({
    required this.attachments,
    this.imageProvider,
    super.key,
  });

  final List<ProjectAttachment> attachments;
  final VisitPhotoImageProvider? imageProvider;

  @override
  Widget build(BuildContext context) {
    final photos = attachments
        .where((attachment) => attachment.isImage && attachment.hasDownloadUrl)
        .toList(growable: false);
    if (photos.isEmpty) return const SizedBox.shrink();

    final visible = photos.take(3).toList(growable: false);
    return Semantics(
      container: true,
      label: '${photos.length} fotografías de la visita',
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: SizedBox(
          height: 72,
          child: Row(
            children: visible.indexed
                .map((entry) {
                  final (index, attachment) = entry;
                  final remaining = photos.length - visible.length;
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index == visible.length - 1 ? 0 : 8,
                    ),
                    child: _PhotoThumbnail(
                      attachment: attachment,
                      imageProvider: imageProvider,
                      remaining: index == visible.length - 1 ? remaining : 0,
                    ),
                  );
                })
                .toList(growable: false),
          ),
        ),
      ),
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  const _PhotoThumbnail({
    required this.attachment,
    required this.imageProvider,
    required this.remaining,
  });

  final ProjectAttachment attachment;
  final VisitPhotoImageProvider? imageProvider;
  final int remaining;

  @override
  Widget build(BuildContext context) {
    final provider =
        imageProvider?.call(attachment) ??
        NetworkImage(attachment.downloadUrl!.trim());
    return SizedBox.square(
      key: ValueKey('visit-photo-${attachment.externalId}'),
      dimension: 72,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image(
              image: provider,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const _PhotoPlaceholder(),
            ),
            if (remaining > 0)
              ColoredBox(
                color: Colors.black54,
                child: Center(
                  child: Text(
                    '+$remaining',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: Color(0xFFE9EDF2),
    child: Center(
      child: Icon(Icons.broken_image_outlined, color: Color(0xFF6F788A)),
    ),
  );
}
