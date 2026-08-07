import 'package:flutter/material.dart';

import '../../data/models/sync/sync_queue_entry.dart';
import '../core/branding/brand_scope.dart';
import 'sync_view_model.dart';

class SyncScreen extends StatelessWidget {
  const SyncScreen({required this.viewModel, super.key});

  final SyncViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sincronización')),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final padding = constraints.maxWidth >= 600 ? 32.0 : 20.0;
              return RefreshIndicator(
                onRefresh: viewModel.load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(padding, 20, padding, 32),
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 760),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'MODO SIN CONEXIÓN',
                              style: TextStyle(
                                color: Color(0xFF6F788A),
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: .7,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              _title(viewModel.items.length),
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 18),
                            _ConnectivityCard(viewModel: viewModel),
                            if (viewModel.errorMessage case final error?) ...[
                              const SizedBox(height: 14),
                              _ErrorNotice(message: error),
                            ],
                            const SizedBox(height: 18),
                            if (viewModel.status == SyncViewStatus.loading)
                              const Card(
                                child: Padding(
                                  padding: EdgeInsets.all(30),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                              )
                            else if (viewModel.items.isEmpty)
                              const _EmptyQueue()
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: viewModel.items.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) =>
                                    _QueueEntryCard(
                                      entry: viewModel.items[index],
                                    ),
                              ),
                            if (viewModel.items.isNotEmpty) ...[
                              const SizedBox(height: 15),
                              const _OrderNotice(),
                              const SizedBox(height: 15),
                              FilledButton.icon(
                                onPressed:
                                    viewModel.status ==
                                        SyncViewStatus.synchronizing
                                    ? null
                                    : viewModel.synchronize,
                                icon:
                                    viewModel.status ==
                                        SyncViewStatus.synchronizing
                                    ? const SizedBox.square(
                                        dimension: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.sync),
                                label: Text(
                                  viewModel.status ==
                                          SyncViewStatus.synchronizing
                                      ? 'Sincronizando…'
                                      : 'Intentar sincronizar ahora',
                                ),
                              ),
                            ],
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

  String _title(int count) {
    if (count == 0) return 'Todo está sincronizado';
    return count == 1 ? '1 registro pendiente' : '$count registros pendientes';
  }
}

class _ConnectivityCard extends StatelessWidget {
  const _ConnectivityCard({required this.viewModel});

  final SyncViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final connected = viewModel.connected;
    final lastAttempt = viewModel.lastAttemptAt;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: connected ? const Color(0xFFEAF8EF) : const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: connected ? const Color(0xFFAADDB9) : const Color(0xFFF0CF8C),
        ),
      ),
      child: Row(
        children: [
          Icon(
            connected ? Icons.wifi : Icons.wifi_off,
            color: connected
                ? const Color(0xFF287A43)
                : const Color(0xFF8A5B00),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  connected ? 'Conexión disponible' : 'Sin conexión estable',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  lastAttempt == null
                      ? connected
                            ? 'Listo para enviar registros pendientes'
                            : 'Se reintentará automáticamente'
                      : 'Último intento: ${_time(lastAttempt)}',
                  style: const TextStyle(
                    color: Color(0xFF6F788A),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QueueEntryCard extends StatelessWidget {
  const _QueueEntryCard({required this.entry});

  final SyncQueueEntry entry;

  @override
  Widget build(BuildContext context) {
    final start = entry.type == SyncQueueEntryType.workdayStart;
    final hasError = entry.lastError?.isNotEmpty == true;
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          start ? 'Inicio de jornada' : 'Cierre de jornada',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(
          'Guardado ${_relativeDate(entry.occurredAtUtc)}',
          style: const TextStyle(color: Color(0xFF6F788A), fontSize: 13),
        ),
        const SizedBox(height: 5),
        Text(
          hasError
              ? entry.lastError!
              : entry.dependsOnId == null
              ? 'Identificador de reintento listo'
              : 'Se enviará después del inicio de jornada',
          style: TextStyle(
            color: hasError ? const Color(0xFFA23A32) : const Color(0xFF536174),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final content = [
              _QueueIcon(start: start),
              const SizedBox(width: 12, height: 12),
              Expanded(child: details),
            ];
            if (constraints.maxWidth < 430) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: content),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _StatusBadge(hasError: hasError),
                  ),
                ],
              );
            }
            return Row(
              children: [
                ...content,
                const SizedBox(width: 10),
                _StatusBadge(hasError: hasError),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _QueueIcon extends StatelessWidget {
  const _QueueIcon({required this.start});

  final bool start;

  @override
  Widget build(BuildContext context) {
    final brand = BrandScope.of(context);
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: brand.primaryColor.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(
        start ? Icons.login : Icons.logout,
        color: brand.primaryColor,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.hasError});

  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: hasError ? const Color(0xFFFFEDEA) : const Color(0xFFFFF3D6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        hasError ? 'Reintentar' : 'En cola',
        style: TextStyle(
          color: hasError ? const Color(0xFFA23A32) : const Color(0xFF825800),
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _OrderNotice extends StatelessWidget {
  const _OrderNotice();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 19, color: Color(0xFF6F788A)),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Los registros pendientes se enviarán respetando el orden en que fueron guardados.',
            style: TextStyle(color: Color(0xFF6F788A), fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _ErrorNotice extends StatelessWidget {
  const _ErrorNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEDEA),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFA23A32)),
          const SizedBox(width: 9),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class _EmptyQueue extends StatelessWidget {
  const _EmptyQueue();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(Icons.cloud_done_outlined, size: 42, color: Color(0xFF287A43)),
            SizedBox(height: 12),
            Text(
              'No hay registros pendientes',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 5),
            Text(
              'Tus operaciones están sincronizadas con el servidor.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF6F788A)),
            ),
          ],
        ),
      ),
    );
  }
}

String _relativeDate(DateTime utc) {
  final local = utc.toLocal();
  final now = DateTime.now();
  final sameDay =
      local.year == now.year &&
      local.month == now.month &&
      local.day == now.day;
  final date = sameDay
      ? 'hoy'
      : '${local.day.toString().padLeft(2, '0')}/'
            '${local.month.toString().padLeft(2, '0')}';
  return '$date a las ${_time(local)}';
}

String _time(DateTime dateTime) {
  final local = dateTime.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}
