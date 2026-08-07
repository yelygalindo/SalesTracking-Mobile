import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/customer/customer_summary.dart';
import '../../data/repositories/customer_repository.dart';
import '../../routing/app_router.dart';
import '../core/branding/brand_scope.dart';
import 'customer_list_view_model.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({required this.repository, super.key});

  final CustomerRepository repository;

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  late final CustomerListViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = CustomerListViewModel(widget.repository)..initialize();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
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
          return LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              final horizontalPadding = constraints.maxWidth >= 600
                  ? 32.0
                  : 20.0;
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          18,
                          horizontalPadding,
                          0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'CRM',
                              style: TextStyle(
                                color: Color(0xFF6F788A),
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: .7,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              _viewModel.totalItems == 0
                                  ? 'Clientes'
                                  : '${_viewModel.totalItems} clientes',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              onChanged: _viewModel.updateSearch,
                              textInputAction: TextInputAction.search,
                              decoration: const InputDecoration(
                                hintText: 'Buscar nombre, empresa, teléfono…',
                                prefixIcon: Icon(Icons.search),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _StatusFilters(viewModel: _viewModel),
                            if (_viewModel.errorMessage case final error?) ...[
                              const SizedBox(height: 12),
                              _CustomerError(
                                message: error,
                                onRetry: _viewModel.refresh,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _CustomerResults(
                          viewModel: _viewModel,
                          wide: wide,
                          horizontalPadding: horizontalPadding,
                        ),
                      ),
                    ],
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

class _StatusFilters extends StatelessWidget {
  const _StatusFilters({required this.viewModel});

  final CustomerListViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterChip(
            label: const Text('Todos'),
            selected: viewModel.selectedStatus == null,
            onSelected: (_) => viewModel.selectStatus(null),
          ),
          for (final status in viewModel.statuses) ...[
            const SizedBox(width: 8),
            FilterChip(
              label: Text(status.label),
              selected: viewModel.selectedStatus?.value == status.value,
              onSelected: (_) => viewModel.selectStatus(status),
            ),
          ],
        ],
      ),
    );
  }
}

class _CustomerResults extends StatelessWidget {
  const _CustomerResults({
    required this.viewModel,
    required this.wide,
    required this.horizontalPadding,
  });

  final CustomerListViewModel viewModel;
  final bool wide;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    if (viewModel.isLoading && viewModel.customers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (viewModel.customers.isEmpty) {
      return RefreshIndicator(
        onRefresh: viewModel.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(horizontalPadding),
          children: const [SizedBox(height: 70), _EmptyCustomers()],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.extentAfter < 280) viewModel.loadMore();
        return false;
      },
      child: RefreshIndicator(
        onRefresh: viewModel.refresh,
        child: GridView.builder(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            4,
            horizontalPadding,
            28,
          ),
          itemCount:
              viewModel.customers.length + (viewModel.isLoadingMore ? 1 : 0),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: wide ? 2 : 1,
            mainAxisExtent: 148,
            crossAxisSpacing: 12,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {
            if (index == viewModel.customers.length) {
              return const Center(child: CircularProgressIndicator());
            }
            return _CustomerCard(customer: viewModel.customers[index]);
          },
        ),
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.customer});

  final CustomerSummary customer;

  @override
  Widget build(BuildContext context) {
    final brand = BrandScope.of(context);
    final contact = customer.phone.isNotEmpty ? customer.phone : customer.email;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: brand.inkColor.withValues(alpha: .09),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(Icons.person_outline, color: brand.inkColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name.isEmpty
                        ? 'Cliente sin nombre'
                        : customer.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    customer.companyName.isEmpty
                        ? 'Empresa no registrada'
                        : customer.companyName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFF6F788A)),
                  ),
                  const Spacer(),
                  if (contact.isNotEmpty)
                    Text(
                      contact,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF536174),
                        fontSize: 12,
                      ),
                    ),
                  if (customer.seller?.name.isNotEmpty == true)
                    Text(
                      'Asignado a ${customer.seller!.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF6F788A),
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _CustomerStatusBadge(status: customer.status),
          ],
        ),
      ),
    );
  }
}

class _CustomerStatusBadge extends StatelessWidget {
  const _CustomerStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final active = normalized.contains('activ');
    final contacted = normalized.contains('contact');
    final color = active
        ? const Color(0xFF287A43)
        : contacted
        ? const Color(0xFF315E9E)
        : const Color(0xFF825800);
    final background = active
        ? const Color(0xFFEAF8EF)
        : contacted
        ? const Color(0xFFEAF1FC)
        : const Color(0xFFFFF3D6);
    return Container(
      constraints: const BoxConstraints(maxWidth: 92),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.isEmpty ? 'Sin estado' : status,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CustomerError extends StatelessWidget {
  const _CustomerError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEDEA),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFA23A32)),
          const SizedBox(width: 9),
          Expanded(child: Text(message)),
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

class _EmptyCustomers extends StatelessWidget {
  const _EmptyCustomers();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Icon(Icons.people_outline, size: 44, color: Color(0xFF6F788A)),
        SizedBox(height: 12),
        Text(
          'No encontramos clientes',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        ),
        SizedBox(height: 5),
        Text(
          'Prueba con otra búsqueda o filtro.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF6F788A)),
        ),
      ],
    );
  }
}
