import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/attachment/project_attachment.dart';
import '../../data/models/project/project_detail.dart';
import '../../data/models/project/project_note.dart';
import '../../data/models/project/project_reminder.dart';
import '../../data/models/project/project_status.dart';
import '../../data/models/project/project_timeline_item.dart';
import '../../data/repositories/project_repository.dart';
import '../../data/repositories/visit_repository.dart';
import '../../data/models/visit/visit_target_type.dart';
import '../../routing/app_router.dart';
import '../core/branding/brand_scope.dart';
import '../core/device_actions.dart';
import '../history/visit_photo_strip.dart';
import 'project_detail_view_model.dart';
import '../visits/visit_action_card.dart';

class ProjectDetailScreen extends StatefulWidget {
  const ProjectDetailScreen({
    required this.repository,
    required this.externalId,
    required this.visitRepository,
    super.key,
  });

  final ProjectRepository repository;
  final String externalId;
  final VisitRepository visitRepository;

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  late final ProjectDetailViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ProjectDetailViewModel(widget.repository, widget.externalId)
      ..load();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _edit() async {
    final changed = await context.push<bool>(
      AppRoutes.editProject(widget.externalId),
    );
    if (changed == true) await _viewModel.load();
  }

  Future<void> _launchAction(Uri uri, String failureMessage) async {
    var launched = false;
    try {
      launched = await launchDeviceAction(uri);
    } on Exception {
      launched = false;
    }
    if (!mounted || launched) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(failureMessage)));
  }

  Future<void> _changeStatus(ProjectDetail project) async {
    final selected = await showModalBottomSheet<ProjectStatus>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 10),
              child: Text(
                'Cambiar estado de la obra',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ),
            ..._viewModel.statusOptions.map((status) {
              final selected =
                  project.status.trim().toLowerCase() ==
                  status.label.trim().toLowerCase();
              return ListTile(
                key: ValueKey('project-status-${status.value}'),
                leading: Icon(
                  selected ? Icons.check_circle : Icons.radio_button_unchecked,
                ),
                title: Text(status.label),
                enabled: !selected,
                onTap: selected
                    ? null
                    : () => Navigator.of(context).pop(status),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (selected == null) return;
    final changed = await _viewModel.changeStatus(selected);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          changed
              ? 'Estado actualizado a ${selected.label}.'
              : _viewModel.errorMessage ?? 'No se cambió el estado.',
        ),
      ),
    );
  }

  Future<void> _addNote() async {
    final content = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const _AddProjectTextSheet(),
    );
    if (content == null) return;
    final saved = await _viewModel.addNote(content);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? 'Nota agregada a la obra.'
              : _viewModel.activityErrorMessage ??
                    'No pudimos agregar la nota.',
        ),
      ),
    );
  }

  Future<void> _addReminder() async {
    final text = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const _AddProjectTextSheet(
        title: 'Nuevo recordatorio de obra',
        subtitle: 'Primero describe qué necesitas recordar.',
        label: 'Recordatorio',
        hint: 'Ej. Confirmar entrega de materiales.',
        fieldKey: ValueKey('project-reminder-field'),
        saveKey: ValueKey('continue-project-reminder-button'),
        actionLabel: 'Elegir fecha',
        icon: Icons.calendar_today_outlined,
      ),
    );
    if (text == null || !mounted) return;
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
      helpText: 'Fecha del recordatorio',
      cancelText: 'Cancelar',
      confirmText: 'Continuar',
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      helpText: 'Hora del recordatorio',
      cancelText: 'Cancelar',
      confirmText: 'Guardar',
    );
    if (time == null || !mounted) return;
    final saved = await _viewModel.addReminder(
      text: text,
      reminderAtUtc: DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ).toUtc(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? 'Recordatorio agregado a la obra.'
              : _viewModel.activityErrorMessage ??
                    'No pudimos agregar el recordatorio.',
        ),
      ),
    );
  }

  Future<void> _completeReminder(String reminderExternalId) async {
    final completed = await _viewModel.completeReminder(reminderExternalId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          completed
              ? 'Recordatorio completado.'
              : _viewModel.activityErrorMessage ??
                    'No pudimos completar el recordatorio.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de obra')),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.status == ProjectDetailViewStatus.loading &&
              _viewModel.project == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final project = _viewModel.project;
          if (project == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _viewModel.errorMessage ?? 'No pudimos cargar la obra.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _viewModel.load,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }
          final locationUri = mapUri(
            latitude: project.latitude,
            longitude: project.longitude,
            address: project.address,
          );
          return LayoutBuilder(
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
                            _ProjectHero(project: project),
                            const SizedBox(height: 12),
                            VisitActionCard(
                              repository: widget.visitRepository,
                              targetType: VisitTargetType.project,
                              targetExternalId: project.externalId,
                              targetName: project.name,
                            ),
                            const SizedBox(height: 12),
                            _ProjectQuickActions(
                              onEdit: _edit,
                              onMap: locationUri == null
                                  ? null
                                  : () => _launchAction(
                                      locationUri,
                                      'No pudimos abrir la ubicación en el mapa.',
                                    ),
                              onVisits: () => context.push(
                                AppRoutes.projectVisits(
                                  project.externalId,
                                  project.name,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _ProjectMetadata(
                              project: project,
                              changingStatus: _viewModel.changingStatus,
                              canChangeStatus:
                                  _viewModel.statusOptions.isNotEmpty,
                              onChangeStatus: () => _changeStatus(project),
                            ),
                            if (project.description.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(18),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Descripción',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 7),
                                      Text(project.description),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            _ProjectRemindersPanel(
                              reminders: _viewModel.reminders,
                              busy: _viewModel.savingReminder,
                              onAdd: _addReminder,
                              onComplete: _completeReminder,
                            ),
                            const SizedBox(height: 16),
                            _ProjectActivitySection(
                              viewModel: _viewModel,
                              onAddNote: _addNote,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ProjectQuickActions extends StatelessWidget {
  const _ProjectQuickActions({
    required this.onEdit,
    required this.onMap,
    required this.onVisits,
  });

  final VoidCallback onEdit;
  final VoidCallback? onMap;
  final VoidCallback onVisits;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 330 ? 3 : 2;
        final itemWidth =
            (constraints.maxWidth - ((columns - 1) * 8)) / columns;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ProjectQuickAction(
              width: itemWidth,
              key: const ValueKey('edit-project-button'),
              icon: Icons.edit_outlined,
              label: 'Editar',
              onPressed: onEdit,
            ),
            _ProjectQuickAction(
              width: itemWidth,
              key: const ValueKey('map-project-button'),
              icon: Icons.map_outlined,
              label: 'Mapa',
              onPressed: onMap,
            ),
            _ProjectQuickAction(
              width: itemWidth,
              key: const ValueKey('project-visits-button'),
              icon: Icons.route_outlined,
              label: 'Visitas',
              onPressed: onVisits,
            ),
          ],
        );
      },
    );
  }
}

class _ProjectQuickAction extends StatelessWidget {
  const _ProjectQuickAction({
    required this.width,
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
  });

  final double width;
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 68,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 21),
            const SizedBox(height: 4),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _ProjectHero extends StatelessWidget {
  const _ProjectHero({required this.project});

  final ProjectDetail project;

  @override
  Widget build(BuildContext context) {
    final brand = BrandScope.of(context);
    final progress = project.progressPercentage.clamp(0, 100) / 100;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            color: brand.inkColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.externalId,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                const SizedBox(height: 14),
                Text(
                  project.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  project.customerName,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        project.sellerName.isEmpty
                            ? 'Sin responsable'
                            : project.sellerName,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text(
                      '${project.progressPercentage.toStringAsFixed(0)}%',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(99),
                  color: brand.primaryColor,
                  backgroundColor: brand.primaryColor.withValues(alpha: .13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectMetadata extends StatelessWidget {
  const _ProjectMetadata({
    required this.project,
    required this.changingStatus,
    required this.canChangeStatus,
    required this.onChangeStatus,
  });

  final ProjectDetail project;
  final bool changingStatus;
  final bool canChangeStatus;
  final VoidCallback onChangeStatus;

  @override
  Widget build(BuildContext context) {
    final items = <_ProjectMetadataItem>[
      _ProjectMetadataItem(
        label: 'Estado',
        value: project.status,
        icon: Icons.swap_horiz,
        onTap: canChangeStatus && !changingStatus ? onChangeStatus : null,
        key: const ValueKey('change-project-status-button'),
        loading: changingStatus,
      ),
      _ProjectMetadataItem(label: 'Inicio', value: _date(project.startDateUtc)),
      _ProjectMetadataItem(
        label: 'Cierre estimado',
        value: _date(project.expectedCloseDateUtc),
      ),
      _ProjectMetadataItem(
        label: 'Monto estimado',
        value: _amount(project.estimatedAmount),
      ),
      _ProjectMetadataItem(
        label: 'Dirección',
        value: project.address,
        fullWidth: true,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = constraints.maxWidth - 20;
        final columns = constraints.maxWidth >= 720
            ? 4
            : constraints.maxWidth >= 330
            ? 2
            : 1;
        final cellWidth = (contentWidth - ((columns - 1) * 8)) / columns;
        return Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items
                  .map(
                    (item) => SizedBox(
                      width: item.fullWidth ? contentWidth : cellWidth,
                      child: _ProjectMetadataCell(item: item),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        );
      },
    );
  }
}

class _ProjectMetadataItem {
  const _ProjectMetadataItem({
    required this.label,
    required this.value,
    this.icon,
    this.onTap,
    this.key,
    this.loading = false,
    this.fullWidth = false,
  });

  final String label;
  final String value;
  final IconData? icon;
  final VoidCallback? onTap;
  final Key? key;
  final bool loading;
  final bool fullWidth;
}

class _ProjectMetadataCell extends StatelessWidget {
  const _ProjectMetadataCell({required this.item});

  final _ProjectMetadataItem item;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: item.key,
      color: const Color(0xFFF6F7F9),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: const TextStyle(
                        color: Color(0xFF6F788A),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.value.isEmpty ? 'No registrado' : item.value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              if (item.loading)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: SizedBox.square(
                    dimension: 17,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (item.icon case final icon?)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(icon, size: 19),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

String _date(DateTime? date) {
  if (date == null) return '';
  final local = date.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/${local.year}';
}

String _amount(double? amount) =>
    amount == null ? '' : 'Bs ${amount.toStringAsFixed(2)}';

class _ProjectRemindersPanel extends StatelessWidget {
  const _ProjectRemindersPanel({
    required this.reminders,
    required this.busy,
    required this.onAdd,
    required this.onComplete,
  });

  final List<ProjectReminder> reminders;
  final bool busy;
  final VoidCallback onAdd;
  final Future<void> Function(String reminderExternalId) onComplete;

  @override
  Widget build(BuildContext context) {
    final pending = reminders
        .where((reminder) => !reminder.completed)
        .toList(growable: false);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_none_outlined),
                const SizedBox(width: 9),
                const Expanded(
                  child: Text(
                    'Próximos recordatorios',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                  ),
                ),
                Text(
                  '${pending.length}',
                  style: const TextStyle(color: Color(0xFF6F788A)),
                ),
                const SizedBox(width: 4),
                IconButton(
                  key: const ValueKey('add-project-reminder-button'),
                  tooltip: 'Nuevo recordatorio de obra',
                  onPressed: busy ? null : onAdd,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (pending.isEmpty)
              const Text(
                'No hay recordatorios pendientes.',
                style: TextStyle(color: Color(0xFF6F788A)),
              )
            else
              ...pending.indexed.map((entry) {
                final (index, reminder) = entry;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == pending.length - 1 ? 0 : 8,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F7F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.only(left: 14, right: 6),
                      title: Text(
                        reminder.text,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        _activityMetadata(
                          reminder.reminderAtUtc,
                          reminder.assignedTo?.name,
                        ),
                      ),
                      trailing: IconButton(
                        key: reminder.externalId == null
                            ? null
                            : ValueKey(
                                'complete-project-reminder-'
                                '${reminder.externalId}',
                              ),
                        tooltip: 'Marcar como completado',
                        onPressed:
                            busy ||
                                reminder.externalId == null ||
                                reminder.externalId!.startsWith('local:')
                            ? null
                            : () => onComplete(reminder.externalId!),
                        icon: const Icon(Icons.check_circle_outline),
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _ProjectActivitySection extends StatelessWidget {
  const _ProjectActivitySection({
    required this.viewModel,
    required this.onAddNote,
  });

  final ProjectDetailViewModel viewModel;
  final VoidCallback onAddNote;

  @override
  Widget build(BuildContext context) {
    final loading = viewModel.loadingActivity;
    final hasContent =
        viewModel.notes.isNotEmpty || viewModel.timeline.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Seguimiento de la obra',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            TextButton.icon(
              key: const ValueKey('add-project-note-button'),
              onPressed: viewModel.savingNote ? null : onAddNote,
              icon: viewModel.savingNote
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_comment_outlined),
              label: const Text('Agregar nota'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (loading && !hasContent)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(30),
              child: Center(child: CircularProgressIndicator()),
            ),
          )
        else ...[
          if (viewModel.activityErrorMessage case final message?) ...[
            _ActivityError(
              message: message,
              onRetry: loading ? null : viewModel.reloadActivity,
            ),
            const SizedBox(height: 12),
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 720;
              final notes = _ProjectNotesPanel(notes: viewModel.notes);
              final timeline = _ProjectTimelinePanel(items: viewModel.timeline);
              if (!wide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [notes, const SizedBox(height: 12), timeline],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: notes),
                  const SizedBox(width: 12),
                  Expanded(child: timeline),
                ],
              );
            },
          ),
        ],
      ],
    );
  }
}

class _ProjectNotesPanel extends StatelessWidget {
  const _ProjectNotesPanel({required this.notes});

  final List<ProjectNote> notes;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.sticky_note_2_outlined),
                SizedBox(width: 9),
                Text(
                  'Notas',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (notes.isEmpty)
              const Text(
                'Todavía no hay notas registradas.',
                style: TextStyle(color: Color(0xFF6F788A)),
              )
            else
              ...notes.indexed.map((entry) {
                final (index, note) = entry;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == notes.length - 1 ? 0 : 14,
                  ),
                  child: _ActivityItem(
                    title: note.content,
                    metadata: _activityMetadata(
                      note.occurredAtUtc,
                      note.createdBy?.name,
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _ProjectTimelinePanel extends StatelessWidget {
  const _ProjectTimelinePanel({required this.items});

  final List<ProjectTimelineItem> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.history_outlined),
                SizedBox(width: 9),
                Text(
                  'Historial',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (items.isEmpty)
              const Text(
                'Todavía no hay actividad registrada.',
                style: TextStyle(color: Color(0xFF6F788A)),
              )
            else
              ...items.indexed.map((entry) {
                final (index, item) = entry;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == items.length - 1 ? 0 : 14,
                  ),
                  child: _ActivityItem(
                    title: item.title.isEmpty ? item.eventTypeName : item.title,
                    description: item.description,
                    metadata: _activityMetadata(
                      item.occurredAtUtc,
                      item.createdBy?.name,
                    ),
                    attachments: _timelineAttachments(item),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  const _ActivityItem({
    required this.title,
    required this.metadata,
    this.description = '',
    this.attachments = const [],
  });

  final String title;
  final String description;
  final String metadata;
  final List<ProjectAttachment> attachments;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 9,
          height: 9,
          margin: const EdgeInsets.only(top: 5),
          decoration: BoxDecoration(
            color: BrandScope.of(context).primaryColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              if (description.trim().isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(description.trim()),
              ],
              const SizedBox(height: 4),
              Text(
                metadata,
                style: const TextStyle(color: Color(0xFF6F788A), fontSize: 11),
              ),
              VisitPhotoStrip(attachments: attachments),
            ],
          ),
        ),
      ],
    );
  }
}

List<ProjectAttachment> _timelineAttachments(ProjectTimelineItem item) {
  final metadata = item.metadataJson;
  if (metadata == null || !metadata.isImage || !metadata.hasDownloadUrl) {
    return const [];
  }
  return [
    ProjectAttachment(
      externalId: metadata.attachmentExternalId.isEmpty
          ? item.externalId
          : metadata.attachmentExternalId,
      fileName: metadata.fileName,
      contentType: metadata.contentType,
      sizeBytes: metadata.sizeBytes,
      attachmentType: metadata.attachmentType,
      caption: null,
      isCover: false,
      downloadUrl: metadata.downloadUrl,
      downloadUrlExpiresAtUtc: metadata.downloadUrlExpiresAtUtc,
      createdAtUtc: item.occurredAtUtc,
      visitExternalId: metadata.visitExternalId ?? item.visitExternalId,
    ),
  ];
}

class _ActivityError extends StatelessWidget {
  const _ActivityError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: const Color(0xFFFFF2E8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_outlined),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
            TextButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

class _AddProjectTextSheet extends StatefulWidget {
  const _AddProjectTextSheet({
    this.title = 'Nueva nota de obra',
    this.subtitle = 'Se conservará la fecha y hora real del dispositivo.',
    this.label = 'Nota',
    this.hint = 'Ej. Se confirmó el avance del segundo piso.',
    this.fieldKey = const ValueKey('project-note-field'),
    this.saveKey = const ValueKey('save-project-note-button'),
    this.actionLabel = 'Guardar nota',
    this.icon = Icons.save_outlined,
  });

  final String title;
  final String subtitle;
  final String label;
  final String hint;
  final Key fieldKey;
  final Key saveKey;
  final String actionLabel;
  final IconData icon;

  @override
  State<_AddProjectTextSheet> createState() => _AddProjectTextSheetState();
}

class _AddProjectTextSheetState extends State<_AddProjectTextSheet> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.title,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(widget.subtitle, style: TextStyle(color: Color(0xFF6F788A))),
              const SizedBox(height: 16),
              TextFormField(
                key: widget.fieldKey,
                controller: _controller,
                autofocus: true,
                minLines: 3,
                maxLines: 6,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: widget.label,
                  hintText: widget.hint,
                  alignLabelWithHint: true,
                ),
                validator: (value) => value?.trim().isEmpty ?? true
                    ? 'Escribe una nota antes de guardarla.'
                    : null,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                key: widget.saveKey,
                onPressed: () {
                  if (_formKey.currentState?.validate() != true) return;
                  Navigator.of(context).pop(_controller.text.trim());
                },
                icon: Icon(widget.icon),
                label: Text(widget.actionLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _activityMetadata(DateTime date, String? author) {
  final local = date.toLocal();
  final formatted =
      '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/${local.year} · '
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
  final normalizedAuthor = author?.trim() ?? '';
  return normalizedAuthor.isEmpty
      ? formatted
      : '$formatted · $normalizedAuthor';
}
