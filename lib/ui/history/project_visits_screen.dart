import 'package:flutter/material.dart';

import '../../data/models/attachment/project_attachment.dart';
import '../../data/models/history/project_visit.dart';
import '../../data/repositories/history_repository.dart';
import '../core/branding/brand_scope.dart';
import 'project_visits_view_model.dart';
import 'visit_photo_strip.dart';

class ProjectVisitsScreen extends StatefulWidget {
  const ProjectVisitsScreen({
    required this.repository,
    required this.projectExternalId,
    required this.projectName,
    super.key,
  });

  final HistoryRepository repository;
  final String projectExternalId;
  final String projectName;

  @override
  State<ProjectVisitsScreen> createState() => _ProjectVisitsScreenState();
}

class _ProjectVisitsScreenState extends State<ProjectVisitsScreen> {
  late final ProjectVisitsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ProjectVisitsViewModel(
      widget.repository,
      widget.projectExternalId,
    )..load();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Visitas de la obra')),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) => LayoutBuilder(
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
                          Text(
                            widget.projectName.isEmpty
                                ? 'OBRA'
                                : widget.projectName.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: BrandScope.of(context).primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .7,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            'Visitas registradas',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Consulta horarios, ubicación, resultado y notas.',
                            style: TextStyle(color: Color(0xFF6F788A)),
                          ),
                          const SizedBox(height: 18),
                          _VisitsBody(viewModel: _viewModel),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _VisitsBody extends StatelessWidget {
  const _VisitsBody({required this.viewModel});

  final ProjectVisitsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    if (viewModel.status == ProjectVisitsStatus.loading &&
        viewModel.visits.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(36),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (viewModel.visits.isEmpty) {
      final failed = viewModel.errorMessage != null;
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              Icon(
                failed ? Icons.cloud_off_outlined : Icons.route_outlined,
                size: 38,
                color: const Color(0xFF6F788A),
              ),
              const SizedBox(height: 12),
              Text(
                viewModel.errorMessage ??
                    'Todavía no hay visitas registradas en esta obra.',
                textAlign: TextAlign.center,
              ),
              if (failed) ...[
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: viewModel.load,
                  child: const Text('Reintentar'),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return Column(
      children: viewModel.visits
          .map(
            (visit) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _VisitCard(
                visit: visit,
                attachments: viewModel.attachmentsFor(visit),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _VisitCard extends StatelessWidget {
  const _VisitCard({required this.visit, required this.attachments});

  final ProjectVisit visit;
  final List<ProjectAttachment> attachments;

  @override
  Widget build(BuildContext context) {
    final brand = BrandScope.of(context);
    final start = visit.visitedAtUtc.toLocal();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
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
                        '${_shortDate(start)} · ${_time(start)}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        [
                          if (visit.sellerName.isNotEmpty) visit.sellerName,
                          if (visit.duration != null)
                            _duration(visit.duration!),
                        ].join(' · '),
                        style: const TextStyle(
                          color: Color(0xFF6F788A),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: visit.isOpen
                        ? brand.primaryColor.withValues(alpha: .12)
                        : const Color(0xFFF0F2F5),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    visit.isOpen ? 'En curso' : 'Cerrada',
                    style: TextStyle(
                      color: visit.isOpen
                          ? brand.primaryColor
                          : const Color(0xFF596273),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _Fact(
              label: 'Ubicación de inicio',
              value:
                  '${visit.latitude.toStringAsFixed(5)}, '
                  '${visit.longitude.toStringAsFixed(5)}',
            ),
            if (visit.result?.trim().isNotEmpty == true)
              _Fact(label: 'Resultado', value: visit.result!.trim()),
            if (visit.notes?.trim().isNotEmpty == true)
              _Fact(label: 'Nota de inicio', value: visit.notes!.trim()),
            if (visit.checkOutNote?.trim().isNotEmpty == true)
              _Fact(label: 'Nota de cierre', value: visit.checkOutNote!.trim()),
            VisitPhotoStrip(attachments: attachments),
          ],
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 126,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF6F788A), fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

String _shortDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/'
    '${value.month.toString().padLeft(2, '0')}/${value.year}';

String _time(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:'
    '${value.minute.toString().padLeft(2, '0')}';

String _duration(Duration value) {
  final hours = value.inHours;
  final minutes = value.inMinutes.remainder(60);
  return hours == 0 ? '$minutes min' : '${hours}h ${minutes}m';
}
