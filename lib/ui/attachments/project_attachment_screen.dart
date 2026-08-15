import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/attachment/attachment_source_file.dart';
import '../../data/models/attachment/attachment_upload_options.dart';
import '../../data/repositories/project_attachment_repository.dart';
import '../../data/services/attachment_picker_service.dart';
import '../../data/services/image_picker_attachment_service.dart';

class ProjectAttachmentScreen extends StatefulWidget {
  const ProjectAttachmentScreen({
    required this.repository,
    required this.projectExternalId,
    required this.visitExternalId,
    this.pickerService,
    super.key,
  });

  final ProjectAttachmentRepository repository;
  final String projectExternalId;
  final String visitExternalId;
  final AttachmentPickerService? pickerService;

  @override
  State<ProjectAttachmentScreen> createState() =>
      _ProjectAttachmentScreenState();
}

class _ProjectAttachmentScreenState extends State<ProjectAttachmentScreen> {
  final _caption = TextEditingController();
  final List<AttachmentSourceFile> _images = [];
  late final AttachmentPickerService _picker;
  AttachmentUploadOptions? _options;
  String _attachmentType = 'photo';
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _picker = widget.pickerService ?? ImagePickerAttachmentService();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final options = await widget.repository.getOptions();
      if (!mounted) return;
      _options = options;
      final types = options.attachmentTypes;
      if (types.isNotEmpty) _attachmentType = types.first.value;
    } catch (_) {
      // Picking remains available offline with the documented photo fallback.
    }
    await _recoverLostImages();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _recoverLostImages() async {
    try {
      final images = await _picker.recoverLostImages();
      if (mounted) _images.addAll(images);
    } catch (_) {
      // There is no lost picker state on platforms without this capability.
    }
  }

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    try {
      final image = await _picker.takePhoto();
      if (image != null && mounted) setState(() => _images.add(image));
    } catch (_) {
      if (mounted) setState(() => _error = 'No pudimos abrir la cámara.');
    }
  }

  Future<void> _pickGallery() async {
    try {
      final images = await _picker.pickFromGallery();
      if (images.isNotEmpty && mounted) setState(() => _images.addAll(images));
    } catch (_) {
      if (mounted) setState(() => _error = 'No pudimos abrir la galería.');
    }
  }

  Future<void> _save() async {
    if (_images.isEmpty) {
      setState(() => _error = 'Agrega al menos una fotografía.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      for (final source in _images) {
        _validate(source);
      }
      await widget.repository.saveAttachments(
        projectExternalId: widget.projectExternalId,
        visitExternalId: widget.visitExternalId,
        sources: _images,
        attachmentType: _attachmentType,
        caption: _caption.text,
      );
      if (mounted) context.pop(true);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _validate(AttachmentSourceFile source) {
    final options = _options;
    if (options == null) return;
    if (options.maxFileSizeBytes > 0 &&
        source.sizeBytes > options.maxFileSizeBytes) {
      throw Exception('La fotografía supera el tamaño permitido.');
    }
    final accepted = options.acceptedFormats
        .expand((format) => format.contentTypes)
        .toSet();
    if (accepted.isNotEmpty && !accepted.contains(source.contentType)) {
      throw Exception('El formato ${source.contentType} no está permitido.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fotos de la visita')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final padding = constraints.maxWidth >= 600 ? 32.0 : 20.0;
                return ListView(
                  padding: EdgeInsets.fromLTRB(padding, 18, padding, 32),
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 760),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Agrega evidencia sin finalizar la visita. Las fotos quedan protegidas en el dispositivo hasta sincronizarse.',
                              style: TextStyle(color: Color(0xFF6F788A)),
                            ),
                            if (_error case final error?) ...[
                              const SizedBox(height: 12),
                              _AttachmentError(message: error),
                            ],
                            const SizedBox(height: 16),
                            if (_images.isEmpty)
                              const Card(
                                child: Padding(
                                  padding: EdgeInsets.all(26),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.photo_camera_outlined,
                                        size: 42,
                                      ),
                                      SizedBox(height: 10),
                                      Text('Aún no agregaste fotografías.'),
                                    ],
                                  ),
                                ),
                              )
                            else
                              _PhotoGrid(
                                images: _images,
                                onRemove: (index) =>
                                    setState(() => _images.removeAt(index)),
                              ),
                            const SizedBox(height: 12),
                            _PickerActions(
                              onCamera: _saving ? null : _takePhoto,
                              onGallery: _saving ? null : _pickGallery,
                            ),
                            const SizedBox(height: 12),
                            if ((_options?.attachmentTypes.length ?? 0) > 1)
                              DropdownButtonFormField<String>(
                                initialValue: _attachmentType,
                                decoration: const InputDecoration(
                                  labelText: 'Tipo de evidencia',
                                ),
                                items: _options!.attachmentTypes
                                    .map(
                                      (type) => DropdownMenuItem(
                                        value: type.value,
                                        child: Text(type.label),
                                      ),
                                    )
                                    .toList(growable: false),
                                onChanged: _saving
                                    ? null
                                    : (value) => setState(
                                        () => _attachmentType =
                                            value ?? _attachmentType,
                                      ),
                              ),
                            if ((_options?.attachmentTypes.length ?? 0) > 1)
                              const SizedBox(height: 12),
                            TextField(
                              key: const ValueKey('attachment-caption'),
                              controller: _caption,
                              enabled: !_saving,
                              decoration: const InputDecoration(
                                labelText: 'Comentario opcional',
                              ),
                            ),
                            const SizedBox(height: 18),
                            FilledButton.icon(
                              key: const ValueKey('save-attachments-button'),
                              onPressed: _saving ? null : _save,
                              icon: _saving
                                  ? const SizedBox.square(
                                      dimension: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.cloud_upload_outlined),
                              label: Text(
                                _saving ? 'Guardando…' : 'Guardar fotografías',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  const _PhotoGrid({required this.images, required this.onRemove});

  final List<AttachmentSourceFile> images;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) => Stack(
        key: ValueKey('attachment-preview-$index'),
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(File(images[index].path), fit: BoxFit.cover),
          ),
          Positioned(
            right: 4,
            top: 4,
            child: IconButton.filledTonal(
              tooltip: 'Quitar foto',
              onPressed: () => onRemove(index),
              icon: const Icon(Icons.close, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerActions extends StatelessWidget {
  const _PickerActions({required this.onCamera, required this.onGallery});

  final VoidCallback? onCamera;
  final VoidCallback? onGallery;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            key: const ValueKey('take-photo-button'),
            onPressed: onCamera,
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text('Cámara'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            key: const ValueKey('pick-gallery-button'),
            onPressed: onGallery,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Galería'),
          ),
        ),
      ],
    );
  }
}

class _AttachmentError extends StatelessWidget {
  const _AttachmentError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEDEA),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Text(message),
    );
  }
}
