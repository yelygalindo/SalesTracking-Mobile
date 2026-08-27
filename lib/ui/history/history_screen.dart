import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/attachment/project_attachment.dart';
import '../../data/models/history/seller_timeline_item.dart';
import '../../data/repositories/history_repository.dart';
import '../../routing/app_router.dart';
import '../core/branding/brand_scope.dart';
import '../core/presentation_labels.dart';
import '../core/navigation/app_primary_navigation_bar.dart';
import 'history_view_model.dart';
import 'visit_photo_strip.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({required this.repository, super.key});

  final HistoryRepository repository;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final HistoryViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = HistoryViewModel(widget.repository)..load();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _viewModel.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Selecciona una fecha',
      cancelText: 'Cancelar',
      confirmText: 'Aplicar',
    );
    if (date != null) await _viewModel.selectDate(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
        actions: [
          IconButton(
            tooltip: 'Sincronización',
            onPressed: () => context.push(AppRoutes.sync),
            icon: const Icon(Icons.cloud_done_outlined),
          ),
        ],
      ),
      bottomNavigationBar: const AppPrimaryNavigationBar(
        selected: AppPrimaryDestination.history,
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) => LayoutBuilder(
          builder: (context, constraints) {
            final padding = constraints.maxWidth >= 600 ? 32.0 : 20.0;
            return RefreshIndicator(
              onRefresh: _viewModel.load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(padding, 18, padding, 32),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 850),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'MI ACTIVIDAD',
                            style: TextStyle(
                              color: BrandScope.of(context).primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .8,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            'Todo lo que registraste',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Actividad ordenada por hora para la fecha seleccionada.',
                            style: TextStyle(color: Color(0xFF6F788A)),
                          ),
                          const SizedBox(height: 18),
                          OutlinedButton.icon(
                            key: const ValueKey('history-date-picker'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF9A3412),
                              side: const BorderSide(color: Color(0xFF9A3412)),
                            ),
                            onPressed: _pickDate,
                            icon: const Icon(Icons.calendar_today_outlined),
                            label: Text(_longDate(_viewModel.selectedDate)),
                          ),
                          const SizedBox(height: 16),
                          _HistoryBody(viewModel: _viewModel),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HistoryBody extends StatelessWidget {
  const _HistoryBody({required this.viewModel});

  final HistoryViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    if (viewModel.status == HistoryViewStatus.loading &&
        viewModel.items.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(36),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (viewModel.items.isEmpty && viewModel.errorMessage != null) {
      return _HistoryMessage(
        icon: Icons.cloud_off_outlined,
        message: viewModel.errorMessage!,
        actionLabel: 'Reintentar',
        onAction: viewModel.load,
      );
    }
    if (viewModel.items.isEmpty) {
      return const _HistoryMessage(
        icon: Icons.event_available_outlined,
        message: 'No hay actividad registrada para esta fecha.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
            child: Column(
              children: viewModel.items
                  .map(
                    (item) => _TimelineRow(
                      item: item,
                      attachments: viewModel.attachmentsFor(item),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        ),
        if (viewModel.errorMessage != null) ...[
          const SizedBox(height: 10),
          Text(
            viewModel.errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        if (viewModel.canLoadMore) ...[
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: viewModel.status == HistoryViewStatus.loadingMore
                ? null
                : viewModel.loadMore,
            child: viewModel.status == HistoryViewStatus.loadingMore
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Cargar más'),
          ),
        ],
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.item, required this.attachments});

  final SellerTimelineItem item;
  final List<ProjectAttachment> attachments;

  @override
  Widget build(BuildContext context) {
    final presentation = _presentation(item);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 62,
            child: Text(
              _time(item.occurredAtUtc.toLocal()),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: presentation.color.withValues(alpha: .13),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  presentation.icon,
                  size: 17,
                  color: presentation.color,
                ),
              ),
              Expanded(
                child: Container(width: 2, color: const Color(0xFFE4E8EF)),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    timelineEventTitle(
                      eventType: item.eventType,
                      serverTitle: item.title.isEmpty
                          ? presentation.fallbackTitle
                          : item.title,
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  if (item.description.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.description.trim(),
                      style: const TextStyle(
                        color: Color(0xFF6F788A),
                        height: 1.35,
                      ),
                    ),
                  ],
                  VisitPhotoStrip(attachments: attachments),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryMessage extends StatelessWidget {
  const _HistoryMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(icon, size: 38, color: const Color(0xFF6F788A)),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

({IconData icon, Color color, String fallbackTitle}) _presentation(
  SellerTimelineItem item,
) {
  final value = '${item.eventType} ${item.resourceType}'.toLowerCase();
  if (value.contains('workday') || value.contains('jornada')) {
    return (
      icon: Icons.work_history_outlined,
      color: const Color(0xFF172C4B),
      fallbackTitle: 'Actividad de jornada',
    );
  }
  if (value.contains('visit') || value.contains('visita')) {
    return (
      icon: Icons.location_on_outlined,
      color: const Color(0xFF0F9F6E),
      fallbackTitle: 'Actividad de visita',
    );
  }
  if (value.contains('note') || value.contains('nota')) {
    return (
      icon: Icons.note_alt_outlined,
      color: const Color(0xFFBD7A00),
      fallbackTitle: 'Nota agregada',
    );
  }
  if (value.contains('photo') || value.contains('attachment')) {
    return (
      icon: Icons.photo_camera_outlined,
      color: const Color(0xFF6B55C5),
      fallbackTitle: 'Evidencia agregada',
    );
  }
  return (
    icon: Icons.check_circle_outline,
    color: const Color(0xFF2B6CB0),
    fallbackTitle: 'Actividad registrada',
  );
}

String _time(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:'
    '${value.minute.toString().padLeft(2, '0')}';

String _longDate(DateTime value) {
  const months = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];
  return '${value.day} de ${months[value.month - 1]} de ${value.year}';
}
