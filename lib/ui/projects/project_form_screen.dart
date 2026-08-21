import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/project_repository.dart';
import '../../data/services/location_service.dart';
import 'project_form_view_model.dart';

class ProjectFormScreen extends StatefulWidget {
  const ProjectFormScreen({
    required this.projectRepository,
    required this.customerRepository,
    required this.locationService,
    this.externalId,
    super.key,
  });

  final ProjectRepository projectRepository;
  final CustomerRepository customerRepository;
  final LocationService locationService;
  final String? externalId;

  @override
  State<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends State<ProjectFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _amount = TextEditingController();
  final _progress = TextEditingController(text: '0');
  final _address = TextEditingController();

  late final ProjectFormViewModel _viewModel;
  String? _customerExternalId;
  DateTime? _startDateUtc;
  DateTime? _expectedCloseDateUtc;

  @override
  void initState() {
    super.initState();
    _viewModel = ProjectFormViewModel(
      widget.projectRepository,
      widget.customerRepository,
      widget.locationService,
      externalId: widget.externalId,
    );
    _initialize();
  }

  Future<void> _initialize() async {
    await _viewModel.initialize();
    final project = _viewModel.project;
    if (project == null || !mounted) return;
    _name.text = project.name;
    _description.text = project.description;
    _amount.text = project.estimatedAmount?.toString() ?? '';
    _progress.text = project.progressPercentage.toStringAsFixed(0);
    _address.text = project.address;
    setState(() {
      _customerExternalId = project.customerExternalId;
      _startDateUtc = project.startDateUtc;
      _expectedCloseDateUtc = project.expectedCloseDateUtc;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _amount.dispose();
    _progress.dispose();
    _address.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final selected = await _pickDate(_startDateUtc);
    if (selected != null && mounted) setState(() => _startDateUtc = selected);
  }

  Future<void> _pickCloseDate() async {
    final selected = await _pickDate(_expectedCloseDateUtc);
    if (selected != null && mounted) {
      setState(() => _expectedCloseDateUtc = selected);
    }
  }

  Future<DateTime?> _pickDate(DateTime? current) async {
    final now = DateTime.now();
    final initial = current?.toLocal() ?? now;
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 10),
    );
    return selected == null
        ? null
        : DateTime(selected.year, selected.month, selected.day).toUtc();
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) return;
    final saved = await _viewModel.save(
      name: _name.text,
      description: _description.text,
      customerExternalId: _customerExternalId,
      estimatedAmount: _number(_amount.text),
      startDateUtc: _startDateUtc,
      expectedCloseDateUtc: _expectedCloseDateUtc,
      progressPercentage: _number(_progress.text),
      address: _address.text,
    );
    if (saved && mounted) context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.externalId == null ? 'Nueva obra' : 'Editar obra'),
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.status == ProjectFormViewStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          return LayoutBuilder(
            builder: (context, constraints) {
              final padding = constraints.maxWidth >= 600 ? 32.0 : 20.0;
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(padding, 18, padding, 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 780),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            widget.externalId == null
                                ? 'Registrar obra'
                                : 'Actualizar obra',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Completa la información principal del proyecto.',
                            style: TextStyle(color: Color(0xFF6F788A)),
                          ),
                          if (_viewModel.errorMessage case final error?) ...[
                            const SizedBox(height: 14),
                            _FormError(
                              message: error,
                              onRetry:
                                  widget.externalId != null &&
                                      _viewModel.project == null
                                  ? _initialize
                                  : null,
                            ),
                          ],
                          const SizedBox(height: 18),
                          TextFormField(
                            key: const ValueKey('project-name-field'),
                            controller: _name,
                            decoration: const InputDecoration(
                              labelText: 'Nombre *',
                            ),
                            validator: (value) => value?.trim().isEmpty == true
                                ? 'Ingresa el nombre de la obra.'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            key: const ValueKey('project-description-field'),
                            controller: _description,
                            minLines: 3,
                            maxLines: 5,
                            decoration: const InputDecoration(
                              labelText: 'Descripción',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            key: const ValueKey('project-customer-dropdown'),
                            child: DropdownButtonFormField<String>(
                              key: ValueKey(
                                'customer-${_customerExternalId ?? 'none'}-'
                                '${_viewModel.customerOptions.length}',
                              ),
                              initialValue: _customerExternalId,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Cliente *',
                              ),
                              items: [
                                if (_customerExternalId != null &&
                                    !_viewModel.customerOptions.any(
                                      (customer) =>
                                          customer.externalId ==
                                          _customerExternalId,
                                    ))
                                  DropdownMenuItem(
                                    value: _customerExternalId,
                                    child: Text(
                                      _viewModel.project?.customerName ??
                                          'Cliente actual',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ..._viewModel.customerOptions
                                    .where(
                                      (customer) =>
                                          customer.externalId.isNotEmpty &&
                                          !customer.externalId.startsWith(
                                            'local:',
                                          ),
                                    )
                                    .map(
                                      (customer) => DropdownMenuItem(
                                        value: customer.externalId,
                                        child: Text(
                                          customer.companyName.isEmpty
                                              ? customer.name
                                              : customer.companyName,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                              ],
                              onChanged: (value) =>
                                  setState(() => _customerExternalId = value),
                              validator: (value) => value == null
                                  ? 'Selecciona un cliente.'
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _ResponsiveRow(
                            first: TextFormField(
                              key: const ValueKey('project-amount-field'),
                              controller: _amount,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Monto estimado',
                              ),
                            ),
                            second: TextFormField(
                              key: const ValueKey('project-progress-field'),
                              controller: _progress,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Avance (%)',
                              ),
                              validator: (value) {
                                final number = _number(value ?? '');
                                if (number != null &&
                                    (number < 0 || number > 100)) {
                                  return 'Usa un valor de 0 a 100.';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          _ResponsiveRow(
                            first: _DateField(
                              label: 'Fecha de inicio',
                              value: _startDateUtc,
                              onTap: _pickStartDate,
                            ),
                            second: _DateField(
                              label: 'Cierre estimado',
                              value: _expectedCloseDateUtc,
                              onTap: _pickCloseDate,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            key: const ValueKey('project-address-field'),
                            controller: _address,
                            decoration: const InputDecoration(
                              labelText: 'Dirección',
                            ),
                          ),
                          const SizedBox(height: 12),
                          _LocationCard(viewModel: _viewModel),
                          const SizedBox(height: 18),
                          FilledButton.icon(
                            key: const ValueKey('save-project-button'),
                            onPressed: _viewModel.isBusy || !_viewModel.canSave
                                ? null
                                : _save,
                            icon:
                                _viewModel.status ==
                                    ProjectFormViewStatus.saving
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.check),
                            label: Text(
                              widget.externalId == null
                                  ? 'Guardar obra'
                                  : 'Actualizar obra',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ResponsiveRow extends StatelessWidget {
  const _ResponsiveRow({required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 580) {
          return Column(children: [first, const SizedBox(height: 12), second]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            const SizedBox(width: 12),
            Expanded(child: second),
          ],
        );
      },
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(value == null ? 'Seleccionar' : _date(value!)),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.viewModel});

  final ProjectFormViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final location = viewModel.location;
    final locating = viewModel.status == ProjectFormViewStatus.locating;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              location == null
                  ? 'Ubicación no registrada'
                  : '${location.latitude.toStringAsFixed(5)}, '
                        '${location.longitude.toStringAsFixed(5)}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              key: const ValueKey('capture-project-location-button'),
              onPressed: viewModel.isBusy ? null : viewModel.captureLocation,
              icon: locating
                  ? const SizedBox.square(
                      dimension: 17,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
              label: const Text('Usar ubicación actual'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormError extends StatelessWidget {
  const _FormError({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

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
          Expanded(child: Text(message)),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

double? _number(String value) =>
    double.tryParse(value.trim().replaceAll(',', '.'));

String _date(DateTime value) {
  final local = value.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/${local.year}';
}
