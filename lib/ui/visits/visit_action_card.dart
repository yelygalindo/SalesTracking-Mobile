import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/visit/current_visit.dart';
import '../../data/models/visit/visit_target_type.dart';
import '../../data/repositories/visit_repository.dart';
import '../../routing/app_router.dart';

class VisitActionCard extends StatefulWidget {
  const VisitActionCard({
    required this.repository,
    required this.targetType,
    required this.targetExternalId,
    required this.targetName,
    super.key,
  });

  final VisitRepository repository;
  final VisitTargetType targetType;
  final String targetExternalId;
  final String targetName;

  @override
  State<VisitActionCard> createState() => _VisitActionCardState();
}

class _VisitActionCardState extends State<VisitActionCard> {
  CurrentVisit? _current;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final current = await widget.repository.getCurrent();
      if (!mounted) return;
      setState(() {
        _current = current;
        _error = null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No pudimos consultar la visita en curso.';
        _loading = false;
      });
    }
  }

  Future<void> _start() async {
    final changed = await context.push<bool>(
      AppRoutes.visitCheckIn(
        widget.targetType,
        widget.targetExternalId,
        widget.targetName,
      ),
    );
    if (changed == true) await _load();
  }

  Future<void> _finish() async {
    final changed = await context.push<bool>(AppRoutes.visitCheckOut);
    if (changed == true) await _load();
  }

  Future<void> _addPhotos(CurrentVisit visit) async {
    final changed = await context.push<bool>(
      AppRoutes.projectAttachments(widget.targetExternalId, visit.externalId),
    );
    if (changed == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Fotografías guardadas.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.targetExternalId.startsWith('local:')) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.cloud_upload_outlined),
          title: Text('Visitas disponibles al sincronizar'),
          subtitle: Text(
            'Primero sincroniza este registro para obtener su ID del servidor.',
          ),
        ),
      );
    }
    if (_loading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    final current = _current;
    final matches =
        current?.matches(widget.targetType, widget.targetExternalId) == true;
    if (matches) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Visita en curso',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text('Iniciada a las ${_time(current!.checkInAtUtc)}'),
              const SizedBox(height: 12),
              if (widget.targetType == VisitTargetType.project) ...[
                OutlinedButton.icon(
                  onPressed: () => _addPhotos(current),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Agregar fotos'),
                ),
                const SizedBox(height: 8),
              ],
              FilledButton.icon(
                onPressed: _finish,
                icon: const Icon(Icons.stop_circle_outlined),
                label: const Text('Finalizar visita'),
              ),
            ],
          ),
        ),
      );
    }
    if (current != null) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('Hay otra visita en curso'),
          subtitle: Text(current.targetName),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null) ...[
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 8),
        ],
        FilledButton.icon(
          onPressed: _start,
          icon: const Icon(Icons.play_arrow),
          label: const Text('Iniciar visita'),
        ),
      ],
    );
  }
}

String _time(DateTime value) {
  final local = value.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}
