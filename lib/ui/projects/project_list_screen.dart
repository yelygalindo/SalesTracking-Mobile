import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/project/project_summary.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/project_repository.dart';
import '../../routing/app_router.dart';
import '../core/branding/brand_scope.dart';
import '../core/presentation_labels.dart';
import '../core/navigation/app_primary_navigation_bar.dart';
import 'project_list_view_model.dart';

class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({
    required this.projectRepository,
    required this.customerRepository,
    super.key,
  });

  final ProjectRepository projectRepository;
  final CustomerRepository customerRepository;

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  late final ProjectListViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ProjectListViewModel(
      widget.projectRepository,
      widget.customerRepository,
    )..initialize();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final changed = await context.push<bool>(AppRoutes.newProject);
    if (changed == true) await _viewModel.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const AppPrimaryNavigationBar(
        selected: AppPrimaryDestination.projects,
      ),
      appBar: AppBar(
        title: const Text('Obras'),
        actions: [
          IconButton(
            tooltip: 'Sincronización',
            onPressed: () => context.push(AppRoutes.sync),
            icon: const Icon(Icons.cloud_sync_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        key: const ValueKey('new-project-button'),
        tooltip: 'Nueva obra',
        onPressed: _create,
        child: const Icon(Icons.add),
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) => LayoutBuilder(
          builder: (context, constraints) {
            final padding = constraints.maxWidth >= 600 ? 32.0 : 20.0;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(padding, 18, padding, 8),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 980),
                      child: _ProjectFilters(viewModel: _viewModel),
                    ),
                  ),
                ),
                if (_viewModel.errorMessage case final message?)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: padding),
                    child: _ProjectError(
                      message: message,
                      onRetry: _viewModel.refresh,
                    ),
                  ),
                const SizedBox(height: 8),
                Expanded(
                  child: _ProjectGrid(
                    viewModel: _viewModel,
                    horizontalPadding: padding,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProjectFilters extends StatelessWidget {
  const _ProjectFilters({required this.viewModel});

  final ProjectListViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final status = DropdownButtonFormField<int>(
          initialValue: viewModel.selectedStatusValue,
          decoration: const InputDecoration(labelText: 'Estado'),
          items: [
            const DropdownMenuItem(value: null, child: Text('Todos')),
            ...viewModel.statusOptions.map(
              (status) => DropdownMenuItem(
                value: status.value,
                child: Text(status.label),
              ),
            ),
          ],
          onChanged: viewModel.selectStatus,
        );
        final customer = DropdownButtonFormField<String>(
          initialValue: viewModel.selectedCustomerId,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Cliente'),
          items: [
            const DropdownMenuItem(value: null, child: Text('Todos')),
            ...viewModel.customerOptions.map(
              (item) => DropdownMenuItem(
                value: item.externalId,
                child: Text(
                  item.companyName.isEmpty ? item.name : item.companyName,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
          onChanged: viewModel.selectCustomer,
        );
        if (constraints.maxWidth < 620) {
          return Column(
            children: [status, const SizedBox(height: 10), customer],
          );
        }
        return Row(
          children: [
            Expanded(child: status),
            const SizedBox(width: 12),
            Expanded(child: customer),
          ],
        );
      },
    );
  }
}

class _ProjectGrid extends StatelessWidget {
  const _ProjectGrid({
    required this.viewModel,
    required this.horizontalPadding,
  });

  final ProjectListViewModel viewModel;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (viewModel.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: viewModel.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(horizontalPadding),
          children: const [
            SizedBox(height: 80),
            Icon(Icons.apartment_outlined, size: 46),
            SizedBox(height: 12),
            Text('No hay obras para mostrar.', textAlign: TextAlign.center),
          ],
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 900 ? 2 : 1;
            return GridView.builder(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                4,
                horizontalPadding,
                90,
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 178,
              ),
              itemCount:
                  viewModel.items.length + (viewModel.isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == viewModel.items.length) {
                  return const Center(child: CircularProgressIndicator());
                }
                final project = viewModel.items[index];
                return _ProjectCard(
                  project: project,
                  onTap: () async {
                    final changed = await context.push<bool>(
                      AppRoutes.projectDetail(project.externalId),
                    );
                    if (changed == true) await viewModel.refresh();
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.project, required this.onTap});

  final ProjectSummary project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brand = BrandScope.of(context);
    final progress = project.progressPercentage.clamp(0, 100) / 100;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('project-card-${project.externalId}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.name.isEmpty
                              ? 'Obra sin nombre'
                              : project.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          project.customerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xFF6F788A)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _StatusBadge(status: project.status),
                ],
              ),
              const Spacer(),
              LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                borderRadius: BorderRadius.circular(99),
                color: brand.primaryColor,
                backgroundColor: brand.primaryColor.withValues(alpha: .13),
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  Text(
                    'Avance ${project.progressPercentage.toStringAsFixed(0)}%',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      project.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF6F788A),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8EF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.isEmpty ? 'Sin estado' : projectStatusLabel(status),
        style: const TextStyle(
          color: Color(0xFF287A43),
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ProjectError extends StatelessWidget {
  const _ProjectError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFFEDEA),
      child: ListTile(
        leading: const Icon(Icons.error_outline),
        title: Text(message),
        trailing: TextButton(
          onPressed: onRetry,
          child: const Text('Reintentar'),
        ),
      ),
    );
  }
}
