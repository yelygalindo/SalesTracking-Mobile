import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/project/project_detail.dart';
import '../../data/repositories/project_repository.dart';
import '../../data/repositories/visit_repository.dart';
import '../../data/models/visit/visit_target_type.dart';
import '../../routing/app_router.dart';
import '../core/branding/brand_scope.dart';
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
                            FilledButton.icon(
                              onPressed: _edit,
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('Editar obra'),
                            ),
                            const SizedBox(height: 12),
                            _ProjectMetadata(project: project),
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
  const _ProjectMetadata({required this.project});

  final ProjectDetail project;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Estado', project.status),
      ('Inicio', _date(project.startDateUtc)),
      ('Cierre estimado', _date(project.expectedCloseDateUtc)),
      ('Monto estimado', _amount(project.estimatedAmount)),
      ('Dirección', project.address),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 620
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items
              .map(
                (item) => SizedBox(
                  width: width,
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.$1,
                            style: const TextStyle(
                              color: Color(0xFF6F788A),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            item.$2.isEmpty ? 'No registrado' : item.$2,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .toList(growable: false),
        );
      },
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
