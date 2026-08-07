import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/visit/visit_target_type.dart';
import '../../data/repositories/visit_repository.dart';
import '../../data/services/location_service.dart';
import 'visit_check_in_view_model.dart';

class VisitCheckInScreen extends StatefulWidget {
  const VisitCheckInScreen({
    required this.repository,
    required this.locationService,
    required this.targetType,
    required this.targetExternalId,
    required this.targetName,
    super.key,
  });

  final VisitRepository repository;
  final LocationService locationService;
  final VisitTargetType targetType;
  final String targetExternalId;
  final String targetName;

  @override
  State<VisitCheckInScreen> createState() => _VisitCheckInScreenState();
}

class _VisitCheckInScreenState extends State<VisitCheckInScreen> {
  final _note = TextEditingController();
  late final VisitCheckInViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = VisitCheckInViewModel(
      widget.repository,
      widget.locationService,
      targetType: widget.targetType,
      targetExternalId: widget.targetExternalId,
      targetName: widget.targetName,
    )..initialize();
  }

  @override
  void dispose() {
    _note.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final success = await _viewModel.checkIn(_note.text);
    if (success && mounted) context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar visita')),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.status == VisitCheckInStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
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
                            widget.targetType.label.toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF6F788A),
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.targetName,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 18),
                          const _GpsNotice(),
                          if (_viewModel.errorMessage case final error?) ...[
                            const SizedBox(height: 12),
                            _VisitError(message: error),
                          ],
                          const SizedBox(height: 14),
                          TextField(
                            controller: _note,
                            minLines: 3,
                            maxLines: 5,
                            decoration: const InputDecoration(
                              labelText: 'Nota opcional',
                              hintText: 'Objetivo de la visita',
                            ),
                          ),
                          const SizedBox(height: 18),
                          FilledButton.icon(
                            onPressed: _viewModel.isBusy ? null : _submit,
                            icon: _viewModel.status == VisitCheckInStatus.saving
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.play_arrow),
                            label: const Text('Confirmar check-in'),
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

class _GpsNotice extends StatelessWidget {
  const _GpsNotice();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: ListTile(
        leading: Icon(Icons.location_on_outlined),
        title: Text('Ubicación de check-in'),
        subtitle: Text(
          'Al confirmar se guardarán la hora real del teléfono y el GPS.',
        ),
      ),
    );
  }
}

class _VisitError extends StatelessWidget {
  const _VisitError({required this.message});

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
