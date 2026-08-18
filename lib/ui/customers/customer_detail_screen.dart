import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/customer/customer_detail.dart';
import '../../data/models/customer/customer_note.dart';
import '../../data/models/customer/customer_reminder.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/visit_repository.dart';
import '../../data/models/visit/visit_target_type.dart';
import '../../routing/app_router.dart';
import '../core/branding/brand_scope.dart';
import 'customer_detail_view_model.dart';
import '../visits/visit_action_card.dart';

class CustomerDetailScreen extends StatefulWidget {
  const CustomerDetailScreen({
    required this.repository,
    required this.externalId,
    required this.visitRepository,
    super.key,
  });

  final CustomerRepository repository;
  final String externalId;
  final VisitRepository visitRepository;

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  late final CustomerDetailViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = CustomerDetailViewModel(widget.repository, widget.externalId)
      ..load();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _edit() async {
    final changed = await context.push<bool>(
      AppRoutes.editCustomer(widget.externalId),
    );
    if (changed == true) await _viewModel.load();
  }

  Future<void> _addNote() async {
    final text = await _promptText(
      title: 'Nueva nota',
      label: 'Nota',
      actionLabel: 'Guardar nota',
      fieldKey: const ValueKey('customer-note-field'),
    );
    if (text == null || !mounted) return;
    await _viewModel.addNote(text);
  }

  Future<void> _addReminder() async {
    final text = await _promptText(
      title: 'Nuevo recordatorio',
      label: '¿Qué necesitas recordar?',
      actionLabel: 'Elegir fecha',
      fieldKey: const ValueKey('customer-reminder-field'),
    );
    if (text == null || !mounted) return;
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (time == null || !mounted) return;
    final localDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    await _viewModel.addReminder(
      text: text,
      reminderAtUtc: localDateTime.toUtc(),
    );
  }

  Future<String?> _promptText({
    required String title,
    required String label,
    required String actionLabel,
    required Key fieldKey,
  }) async {
    final value = await showDialog<String>(
      context: context,
      builder: (context) => _ActivityTextDialog(
        title: title,
        label: label,
        actionLabel: actionLabel,
        fieldKey: fieldKey,
      ),
    );
    return value?.isEmpty == true ? null : value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de cliente'),
        actions: [
          IconButton(
            tooltip: 'Sincronización',
            onPressed: () => context.push(AppRoutes.sync),
            icon: const Icon(Icons.cloud_sync_outlined),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.status == CustomerDetailViewStatus.loading &&
              _viewModel.customer == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final customer = _viewModel.customer;
          if (customer == null) {
            return _DetailError(
              message:
                  _viewModel.errorMessage ?? 'No pudimos cargar el cliente.',
              onRetry: _viewModel.load,
            );
          }
          final pendingSync = customer.externalId.startsWith('local:');
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
                        constraints: const BoxConstraints(maxWidth: 820),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _ProfileCard(customer: customer),
                            if (pendingSync) ...[
                              const SizedBox(height: 12),
                              const _PendingCustomerNotice(),
                            ],
                            const SizedBox(height: 12),
                            VisitActionCard(
                              repository: widget.visitRepository,
                              targetType: VisitTargetType.customer,
                              targetExternalId: customer.externalId,
                              targetName: customer.name,
                            ),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              key: const ValueKey('edit-customer-button'),
                              onPressed: pendingSync ? null : _edit,
                              icon: const Icon(Icons.edit_outlined),
                              label: Text(
                                pendingSync
                                    ? 'Disponible al sincronizar'
                                    : 'Editar cliente',
                              ),
                            ),
                            const SizedBox(height: 12),
                            _StatusCard(
                              viewModel: _viewModel,
                              customer: customer,
                            ),
                            if (_viewModel.errorMessage case final error?) ...[
                              const SizedBox(height: 12),
                              _InlineError(message: error),
                            ],
                            const SizedBox(height: 22),
                            _SectionTitle(
                              title: 'Próximos recordatorios',
                              count: customer.reminders
                                  .where((reminder) => !reminder.completed)
                                  .length,
                              onAdd: _viewModel.isBusy ? null : _addReminder,
                              addKey: const ValueKey(
                                'add-customer-reminder-button',
                              ),
                              addTooltip: 'Nuevo recordatorio',
                            ),
                            const SizedBox(height: 10),
                            _ReminderList(
                              reminders: customer.reminders,
                              enabled: !_viewModel.isBusy,
                              onComplete: _viewModel.completeReminder,
                            ),
                            const SizedBox(height: 22),
                            _SectionTitle(
                              title: 'Notas',
                              count: customer.notes.length,
                              onAdd: _viewModel.isBusy ? null : _addNote,
                              addKey: const ValueKey(
                                'add-customer-note-button',
                              ),
                              addTooltip: 'Nueva nota',
                            ),
                            const SizedBox(height: 10),
                            _NoteList(notes: customer.notes),
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

class _ActivityTextDialog extends StatefulWidget {
  const _ActivityTextDialog({
    required this.title,
    required this.label,
    required this.actionLabel,
    required this.fieldKey,
  });

  final String title;
  final String label;
  final String actionLabel;
  final Key fieldKey;

  @override
  State<_ActivityTextDialog> createState() => _ActivityTextDialogState();
}

class _ActivityTextDialogState extends State<_ActivityTextDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        key: widget.fieldKey,
        controller: _controller,
        autofocus: true,
        minLines: 2,
        maxLines: 4,
        decoration: InputDecoration(labelText: widget.label),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: Text(widget.actionLabel),
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.customer});

  final CustomerDetail customer;

  @override
  Widget build(BuildContext context) {
    final brand = BrandScope.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: brand.inkColor.withValues(alpha: .09),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(Icons.business_outlined, color: brand.inkColor),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name.isEmpty
                            ? 'Cliente sin nombre'
                            : customer.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        customer.companyName,
                        style: const TextStyle(color: Color(0xFF6F788A)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _InfoRow(
              icon: Icons.phone_outlined,
              label: 'Teléfono',
              value: customer.phone,
            ),
            _InfoRow(
              icon: Icons.mail_outline,
              label: 'Correo',
              value: customer.email,
            ),
            _InfoRow(
              icon: Icons.location_on_outlined,
              label: 'Dirección',
              value: customer.address,
            ),
            _InfoRow(
              icon: Icons.badge_outlined,
              label: 'Vendedor',
              value: customer.seller?.name ?? '',
              last: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.last = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF6F788A)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF6F788A),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(value.isEmpty ? 'No registrado' : value),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.viewModel, required this.customer});

  final CustomerDetailViewModel viewModel;
  final CustomerDetail customer;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estado comercial',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Actualiza la etapa del cliente.',
                    style: TextStyle(color: Color(0xFF6F788A), fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            DropdownButton<int>(
              key: const ValueKey('customer-status-dropdown'),
              value:
                  viewModel.statuses.any(
                    (status) => status.value == customer.statusId,
                  )
                  ? customer.statusId
                  : null,
              hint: Text(customer.status.isEmpty ? 'Estado' : customer.status),
              onChanged:
                  viewModel.isBusy || customer.externalId.startsWith('local:')
                  ? null
                  : (value) {
                      if (value == null) return;
                      final status = viewModel.statuses.firstWhere(
                        (item) => item.value == value,
                      );
                      viewModel.changeStatus(status);
                    },
              items: viewModel.statuses
                  .map(
                    (status) => DropdownMenuItem<int>(
                      value: status.value,
                      child: Text(status.label),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.count,
    this.onAdd,
    this.addKey,
    this.addTooltip,
  });

  final String title;
  final int count;
  final VoidCallback? onAdd;
  final Key? addKey;
  final String? addTooltip;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        Text('$count', style: const TextStyle(color: Color(0xFF6F788A))),
        if (addTooltip != null) ...[
          const SizedBox(width: 4),
          IconButton(
            key: addKey,
            tooltip: addTooltip,
            onPressed: onAdd,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ],
    );
  }
}

class _ReminderList extends StatelessWidget {
  const _ReminderList({
    required this.reminders,
    required this.enabled,
    required this.onComplete,
  });

  final List<CustomerReminder> reminders;
  final bool enabled;
  final Future<bool> Function(String reminderExternalId) onComplete;

  @override
  Widget build(BuildContext context) {
    final pending = reminders.where((reminder) => !reminder.completed).toList();
    if (pending.isEmpty) {
      return const _EmptySection(message: 'No hay recordatorios pendientes.');
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: pending.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final reminder = pending[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.notifications_none),
            title: Text(reminder.text),
            subtitle: Text(_dateTime(reminder.reminderAtUtc)),
            trailing: IconButton(
              key: ValueKey('complete-reminder-${reminder.externalId}'),
              tooltip: 'Marcar como completado',
              onPressed:
                  enabled &&
                      reminder.externalId != null &&
                      !reminder.externalId!.startsWith('local:')
                  ? () => onComplete(reminder.externalId!)
                  : null,
              icon: const Icon(Icons.check_circle_outline),
            ),
          ),
        );
      },
    );
  }
}

class _NoteList extends StatelessWidget {
  const _NoteList({required this.notes});

  final List<CustomerNote> notes;

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) {
      return const _EmptySection(message: 'No hay notas registradas.');
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: notes.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final note = notes[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.notes_outlined),
            title: Text(note.text),
            subtitle: Text(
              '${_dateTime(note.createdAtUtc)} · ${note.author?.name ?? 'Usuario'}',
            ),
          ),
        );
      },
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF6F788A)),
        ),
      ),
    );
  }
}

class _PendingCustomerNotice extends StatelessWidget {
  const _PendingCustomerNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0CF8C)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.cloud_upload_outlined, color: Color(0xFF825800)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Este cliente está guardado en el dispositivo. Podrás editarlo, agregar notas y crear recordatorios después de sincronizarlo.',
              style: TextStyle(color: Color(0xFF6A4A08)),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    );
  }
}

class _DetailError extends StatelessWidget {
  const _DetailError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 42),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

String _dateTime(DateTime utc) {
  final local = utc.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')} · '
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}
