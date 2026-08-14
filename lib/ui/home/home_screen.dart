import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../routing/app_router.dart';
import '../auth/auth_view_model.dart';
import '../core/branding/brand_scope.dart';
import '../core/navigation/app_primary_navigation_bar.dart';
import '../workday/workday_view_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.authViewModel,
    required this.workdayViewModel,
    super.key,
  });

  final AuthViewModel authViewModel;
  final WorkdayViewModel workdayViewModel;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.workdayViewModel.status == WorkdayStatus.initial) {
      widget.workdayViewModel.loadCurrent();
    }
  }

  @override
  Widget build(BuildContext context) {
    final brand = BrandScope.of(context);
    final user = widget.authViewModel.session!.user;

    return Scaffold(
      bottomNavigationBar: const AppPrimaryNavigationBar(
        selected: AppPrimaryDestination.home,
      ),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: brand.inkColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                brand.monogram,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 9),
            Flexible(
              child: Text(
                brand.appName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            key: const ValueKey('logout-button'),
            tooltip: 'Cerrar sesión',
            onPressed: widget.authViewModel.logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: widget.workdayViewModel,
        builder: (context, _) {
          final viewModel = widget.workdayViewModel;
          return LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth >= 600
                  ? 32.0
                  : 20.0;
              return RefreshIndicator(
                onRefresh: viewModel.loadCurrent,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    18,
                    horizontalPadding,
                    32,
                  ),
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 840),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _spanishDate(DateTime.now()),
                              style: TextStyle(
                                color: brand.primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: .6,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              'Hola, ${user.displayName} 👋',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              viewModel.hasOpenWorkday
                                  ? 'Tu jornada está activa.'
                                  : 'Antes de comenzar tus visitas, abre tu jornada.',
                              style: const TextStyle(color: Color(0xFF6F788A)),
                            ),
                            if (viewModel.errorMessage case final message?) ...[
                              const SizedBox(height: 16),
                              _ErrorBanner(
                                message: message,
                                onRetry: viewModel.loadCurrent,
                              ),
                            ],
                            if (viewModel.hasPendingSync) ...[
                              const SizedBox(height: 16),
                              _SyncBanner(
                                count: viewModel.pendingCount,
                                onTap: () => context.push(AppRoutes.sync),
                              ),
                            ],
                            const SizedBox(height: 20),
                            if (viewModel.status == WorkdayStatus.loading)
                              const Card(
                                child: Padding(
                                  padding: EdgeInsets.all(28),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                              )
                            else if (viewModel.hasOpenWorkday)
                              _ActiveWorkdayCard(
                                viewModel: viewModel,
                                onClose: () =>
                                    context.push(AppRoutes.closeWorkday),
                              )
                            else
                              _ClosedWorkdayCard(viewModel: viewModel),
                            const SizedBox(height: 24),
                            Text(
                              'Ver',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 12),
                            _QuickActions(
                              onCustomers: () =>
                                  context.push(AppRoutes.customers),
                              onProjects: () =>
                                  context.push(AppRoutes.projects),
                              onHistory: () => context.push(AppRoutes.history),
                            ),
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

class _ClosedWorkdayCard extends StatelessWidget {
  const _ClosedWorkdayCard({required this.viewModel});

  final WorkdayViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final brand = BrandScope.of(context);
    final starting = viewModel.status == WorkdayStatus.starting;
    final pending = viewModel.hasPendingSync;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ESTADO',
                        style: TextStyle(
                          color: Color(0xFF6F788A),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 9),
                      Text(
                        '●  Cerrada',
                        style: TextStyle(
                          color: Color(0xFF6F788A),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.work_outline, size: 34),
              ],
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              key: const ValueKey('start-workday-button'),
              style: FilledButton.styleFrom(
                backgroundColor: brand.primaryColor,
                foregroundColor: brand.inkColor,
              ),
              onPressed: starting || pending ? null : viewModel.startWorkday,
              icon: starting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.3,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(
                starting
                    ? 'Obteniendo ubicación…'
                    : pending
                    ? 'Sincronización pendiente'
                    : 'Iniciar jornada',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncBanner extends StatelessWidget {
  const _SyncBanner({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final noun = count == 1 ? 'operación guardada' : 'operaciones guardadas';
    final verb = count == 1 ? 'enviará' : 'enviarán';
    return Material(
      color: const Color(0xFFFFF7E6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFF0CF8C)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.cloud_upload_outlined, color: Color(0xFF8A5B00)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$count $noun. Se $verb automáticamente al recuperar conexión.',
                  style: const TextStyle(
                    color: Color(0xFF6B4800),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, color: Color(0xFF8A5B00)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveWorkdayCard extends StatelessWidget {
  const _ActiveWorkdayCard({required this.viewModel, required this.onClose});

  final WorkdayViewModel viewModel;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final workday = viewModel.workday!;
    final localStart = workday.startedAtUtc.toLocal();
    final duration = DateTime.now().difference(localStart);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'COMENZÓ',
                        style: TextStyle(
                          color: Color(0xFF6F788A),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '●  ${_time(localStart)}',
                        style: const TextStyle(
                          color: Color(0xFF0F9F6E),
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'DURACIÓN',
                      style: TextStyle(
                        color: Color(0xFF6F788A),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _duration(duration),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          key: const ValueKey('finish-workday-button'),
          onPressed: onClose,
          icon: const Icon(Icons.stop_circle_outlined),
          label: const Text('Finalizar jornada'),
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onCustomers,
    required this.onProjects,
    required this.onHistory,
  });

  final VoidCallback onCustomers;
  final VoidCallback onProjects;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _QuickActionCard(
        icon: Icons.people_outline,
        title: 'Clientes',
        subtitle: 'Consultar o registrar',
        onTap: onCustomers,
      ),
      _QuickActionCard(
        icon: Icons.apartment_outlined,
        title: 'Obras',
        subtitle: 'Ver asignadas',
        onTap: onProjects,
      ),
      _QuickActionCard(
        icon: Icons.history,
        title: 'Historial',
        subtitle: 'Revisar actividad',
        onTap: onHistory,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 700 ? 3 : 2;
        final width = (constraints.maxWidth - ((columns - 1) * 8)) / columns;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: cards
              .map((card) => SizedBox(width: width, child: card))
              .toList(growable: false),
        );
      },
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon),
              const SizedBox(height: 13),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFF6F788A), fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFF0F1),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
            TextButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

String _spanishDate(DateTime value) {
  const weekdays = [
    'lunes',
    'martes',
    'miércoles',
    'jueves',
    'viernes',
    'sábado',
    'domingo',
  ];
  const months = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];
  final local = value.toLocal();
  final weekday = weekdays[local.weekday - 1];
  return '${weekday[0].toUpperCase()}${weekday.substring(1)}, ${local.day} de ${months[local.month - 1]}';
}

String _time(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _duration(Duration value) {
  final hours = value.inHours;
  final minutes = value.inMinutes.remainder(60);
  return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
}
