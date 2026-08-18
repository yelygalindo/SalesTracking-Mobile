import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/visit_repository.dart';
import '../../data/services/location_service.dart';
import 'visit_check_out_view_model.dart';

class VisitCheckOutScreen extends StatefulWidget {
  const VisitCheckOutScreen({
    required this.repository,
    required this.locationService,
    super.key,
  });

  final VisitRepository repository;
  final LocationService locationService;

  @override
  State<VisitCheckOutScreen> createState() => _VisitCheckOutScreenState();
}

class _VisitCheckOutScreenState extends State<VisitCheckOutScreen> {
  static const _resultOptions = [
    'Gestión realizada',
    'Requiere seguimiento',
    'No fue atendido',
    'Reprogramada',
    'Otro',
  ];

  final _otherResult = TextEditingController();
  final _note = TextEditingController();
  String? _selectedResult;
  late final VisitCheckOutViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = VisitCheckOutViewModel(
      widget.repository,
      widget.locationService,
    )..initialize();
  }

  @override
  void dispose() {
    _otherResult.dispose();
    _note.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final result = _selectedResult == 'Otro'
        ? _otherResult.text.trim()
        : _selectedResult;
    final success = await _viewModel.checkOut(result: result, note: _note.text);
    if (success && mounted) context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Finalizar visita')),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.status == VisitCheckOutStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          final visit = _viewModel.current;
          return LayoutBuilder(
            builder: (context, constraints) {
              final padding = constraints.maxWidth >= 600 ? 32.0 : 20.0;
              return ListView(
                padding: EdgeInsets.fromLTRB(padding, 20, padding, 32),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 680),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            visit?.type.label.toUpperCase() ?? 'VISITA',
                            style: const TextStyle(
                              color: Color(0xFF6F788A),
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            visit?.targetName ?? 'Sin visita activa',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          if (_viewModel.errorMessage case final error?) ...[
                            const SizedBox(height: 12),
                            _CheckOutError(message: error),
                          ],
                          const SizedBox(height: 18),
                          const Text(
                            '¿Cómo terminó la visita? (opcional)',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _resultOptions
                                .map(
                                  (option) => ChoiceChip(
                                    key: ValueKey(
                                      'visit-result-${option.toLowerCase()}',
                                    ),
                                    label: Text(option),
                                    selected: _selectedResult == option,
                                    onSelected: _viewModel.isBusy
                                        ? null
                                        : (selected) => setState(() {
                                            _selectedResult = selected
                                                ? option
                                                : null;
                                          }),
                                  ),
                                )
                                .toList(growable: false),
                          ),
                          if (_selectedResult == 'Otro') ...[
                            const SizedBox(height: 12),
                            TextField(
                              key: const ValueKey(
                                'visit-check-out-other-result',
                              ),
                              controller: _otherResult,
                              decoration: const InputDecoration(
                                labelText: 'Especifica el resultado',
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          TextField(
                            key: const ValueKey('visit-check-out-note'),
                            controller: _note,
                            minLines: 3,
                            maxLines: 5,
                            decoration: const InputDecoration(
                              labelText: 'Notas del cierre',
                            ),
                          ),
                          const SizedBox(height: 18),
                          FilledButton.icon(
                            key: const ValueKey('confirm-visit-check-out'),
                            onPressed: visit == null || _viewModel.isBusy
                                ? null
                                : _submit,
                            icon:
                                _viewModel.status == VisitCheckOutStatus.saving
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.stop_circle_outlined),
                            label: const Text('Confirmar check-out'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _CheckOutError extends StatelessWidget {
  const _CheckOutError({required this.message});

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
