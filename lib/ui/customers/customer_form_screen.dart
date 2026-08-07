import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/customer_repository.dart';
import '../../data/services/location_service.dart';
import 'customer_form_view_model.dart';

class CustomerFormScreen extends StatefulWidget {
  const CustomerFormScreen({
    required this.repository,
    required this.locationService,
    this.externalId,
    super.key,
  });

  final CustomerRepository repository;
  final LocationService locationService;
  final String? externalId;

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  late final CustomerFormViewModel _viewModel;
  bool _populated = false;

  @override
  void initState() {
    super.initState();
    _viewModel = CustomerFormViewModel(
      widget.repository,
      widget.locationService,
      externalId: widget.externalId,
    )..addListener(_populateInitialValues);
    _viewModel.initialize();
  }

  void _populateInitialValues() {
    final customer = _viewModel.customer;
    if (_populated || customer == null) return;
    _populated = true;
    _nameController.text = customer.name;
    _companyController.text = customer.companyName;
    _phoneController.text = customer.phone;
    _emailController.text = customer.email;
    _addressController.text = customer.address;
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _nameController.dispose();
    _companyController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) return;
    final saved = await _viewModel.save(
      name: _nameController.text,
      companyName: _companyController.text,
      phone: _phoneController.text,
      email: _emailController.text,
      address: _addressController.text,
    );
    if (saved && mounted) context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.externalId == null ? 'Nuevo cliente' : 'Editar cliente',
        ),
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.status == CustomerFormViewStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          return LayoutBuilder(
            builder: (context, constraints) {
              final padding = constraints.maxWidth >= 600 ? 32.0 : 20.0;
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(padding, 18, padding, 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'DATOS COMERCIALES',
                            style: TextStyle(
                              color: Color(0xFF6F788A),
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .7,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.externalId == null
                                ? 'Registrar cliente'
                                : 'Actualizar cliente',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          if (_viewModel.errorMessage case final error?) ...[
                            const SizedBox(height: 14),
                            _FormError(message: error),
                          ],
                          const SizedBox(height: 18),
                          TextFormField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Nombre *',
                              hintText: 'Nombre del contacto',
                            ),
                            validator: _required,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _companyController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Empresa *',
                              hintText: 'Razón social o empresa',
                            ),
                            validator: _required,
                          ),
                          const SizedBox(height: 14),
                          _ContactFields(
                            phoneController: _phoneController,
                            emailController: _emailController,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _addressController,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              labelText: 'Dirección',
                              hintText: 'Calle, número, ciudad',
                            ),
                          ),
                          const SizedBox(height: 14),
                          _LocationCard(viewModel: _viewModel),
                          const SizedBox(height: 14),
                          const Card(
                            child: Padding(
                              padding: EdgeInsets.all(15),
                              child: Row(
                                children: [
                                  Icon(Icons.badge_outlined),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'El backend asignará por defecto al vendedor que registra el cliente.',
                                      style: TextStyle(
                                        color: Color(0xFF6F788A),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          FilledButton.icon(
                            onPressed: _viewModel.isBusy ? null : _save,
                            icon:
                                _viewModel.status ==
                                    CustomerFormViewStatus.saving
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.check),
                            label: Text(
                              _viewModel.status == CustomerFormViewStatus.saving
                                  ? 'Guardando…'
                                  : 'Guardar cliente',
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

class _ContactFields extends StatelessWidget {
  const _ContactFields({
    required this.phoneController,
    required this.emailController,
  });

  final TextEditingController phoneController;
  final TextEditingController emailController;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final phone = TextFormField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Teléfono *',
            hintText: '700 00000',
          ),
          validator: _required,
        );
        final email = TextFormField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Correo *',
            hintText: 'correo@empresa.com',
          ),
          validator: (value) {
            final required = _required(value);
            if (required != null) return required;
            if (!value!.contains('@')) return 'Ingresa un correo válido.';
            return null;
          },
        );
        if (constraints.maxWidth >= 600) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: phone),
              const SizedBox(width: 12),
              Expanded(child: email),
            ],
          );
        }
        return Column(children: [phone, const SizedBox(height: 14), email]);
      },
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.viewModel});

  final CustomerFormViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final location = viewModel.location;
    final locating = viewModel.status == CustomerFormViewStatus.locating;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 126,
            color: const Color(0xFFE9EEF4),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  location == null
                      ? Icons.location_off_outlined
                      : Icons.location_on,
                  size: 35,
                  color: const Color(0xFF536174),
                ),
                const SizedBox(height: 5),
                Text(
                  location == null
                      ? 'Ubicación opcional'
                      : '${location.latitude.toStringAsFixed(5)}, '
                            '${location.longitude.toStringAsFixed(5)}',
                  style: const TextStyle(
                    color: Color(0xFF536174),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(13),
            child: OutlinedButton.icon(
              onPressed: viewModel.isBusy ? null : viewModel.captureLocation,
              icon: locating
                  ? const SizedBox.square(
                      dimension: 17,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
              label: Text(
                locating ? 'Obteniendo ubicación…' : 'Usar ubicación actual',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormError extends StatelessWidget {
  const _FormError({required this.message});

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

String? _required(String? value) {
  return value == null || value.trim().isEmpty ? 'Campo obligatorio.' : null;
}
