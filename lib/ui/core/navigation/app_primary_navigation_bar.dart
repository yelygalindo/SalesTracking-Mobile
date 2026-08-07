import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/app_router.dart';

enum AppPrimaryDestination { home, customers, projects, history }

class AppPrimaryNavigationBar extends StatelessWidget {
  const AppPrimaryNavigationBar({required this.selected, super.key});

  final AppPrimaryDestination selected;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selected.index,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      onDestinationSelected: (index) {
        final destination = AppPrimaryDestination.values[index];
        if (destination == selected) return;
        context.go(_route(destination));
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Inicio',
        ),
        NavigationDestination(
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people),
          label: 'Clientes',
        ),
        NavigationDestination(
          icon: Icon(Icons.apartment_outlined),
          selectedIcon: Icon(Icons.apartment),
          label: 'Obras',
        ),
        NavigationDestination(
          icon: Icon(Icons.history_outlined),
          selectedIcon: Icon(Icons.history),
          label: 'Historial',
        ),
      ],
    );
  }

  String _route(AppPrimaryDestination destination) => switch (destination) {
    AppPrimaryDestination.home => AppRoutes.home,
    AppPrimaryDestination.customers => AppRoutes.customers,
    AppPrimaryDestination.projects => AppRoutes.projects,
    AppPrimaryDestination.history => AppRoutes.history,
  };
}
