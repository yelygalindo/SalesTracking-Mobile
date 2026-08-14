import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../routing/app_router.dart';
import 'workday_view_model.dart';

class CloseWorkdayScreen extends StatefulWidget {
  const CloseWorkdayScreen({required this.viewModel, super.key});

  final WorkdayViewModel viewModel;

  @override
  State<CloseWorkdayScreen> createState() => _CloseWorkdayScreenState();
}

class _CloseWorkdayScreenState extends State<CloseWorkdayScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.viewModel.hasOpenWorkday) {
        unawaited(widget.viewModel.prepareCloseLocation());
      }
    });
  }

  Future<void> _close() async {
    if (await widget.viewModel.closeWorkday() && mounted) {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: const Text('Finalizar jornada'),
      ),
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          final viewModel = widget.viewModel;
          final workday = viewModel.workday;
          if (workday == null || !workday.isOpen) {
            return Center(
              child: TextButton(
                onPressed: () => context.go(AppRoutes.home),
                child: const Text('No hay una jornada abierta'),
              ),
            );
          }

          final duration = DateTime.now().difference(
            workday.startedAtUtc.toLocal(),
          );
          final location = viewModel.closeLocation;
          final locating = viewModel.status == WorkdayStatus.locating;
          final closing = viewModel.status == WorkdayStatus.closing;

          return LayoutBuilder(
            builder: (context, constraints) => ListView(
              padding: EdgeInsets.symmetric(
                horizontal: constraints.maxWidth >= 600 ? 32 : 20,
                vertical: 18,
              ),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'RESUMEN DEL DÍA',
                          style: TextStyle(
                            color: Color(0xFFF97316),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '¿Terminaste por hoy?',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Revisa la ubicación antes de cerrar.',
                          style: TextStyle(color: Color(0xFF6F788A)),
                        ),
                        const SizedBox(height: 18),
                        _SummaryCard(
                          label: 'DURACIÓN',
                          value: _duration(duration),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              Container(
                                height: 140,
                                color: const Color(0xFFE8ECEB),
                                alignment: Alignment.center,
                                child: locating
                                    ? const CircularProgressIndicator()
                                    : Icon(
                                        location == null
                                            ? Icons.location_off_outlined
                                            : Icons.location_on,
                                        size: 46,
                                        color: location == null
                                            ? const Color(0xFF6F788A)
                                            : const Color(0xFFF97316),
                                      ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'UBICACIÓN DE CIERRE',
                                            style: TextStyle(
                                              color: Color(0xFF6F788A),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            location == null
                                                ? 'No detectada'
                                                : 'Precisión aproximada: ${location.accuracyMeters.round()} m',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (location != null)
                                      const Chip(label: Text('GPS verificado')),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (viewModel.errorMessage case final message?) ...[
                          const SizedBox(height: 14),
                          Text(
                            message,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: locating
                                ? null
                                : viewModel.prepareCloseLocation,
                            icon: const Icon(Icons.my_location),
                            label: const Text('Reintentar ubicación'),
                          ),
                        ],
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          key: const ValueKey('close-workday-button'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFDC3E4D),
                          ),
                          onPressed: location == null || closing
                              ? null
                              : _close,
                          icon: closing
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.3,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.stop_circle_outlined),
                          label: Text(
                            closing ? 'Cerrando jornada…' : 'Cerrar jornada',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6F788A),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

String _duration(Duration value) {
  final hours = value.inHours;
  final minutes = value.inMinutes.remainder(60);
  return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
}
