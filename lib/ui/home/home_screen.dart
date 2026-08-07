import 'package:flutter/material.dart';

import '../auth/auth_view_model.dart';
import '../core/branding/brand_scope.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.viewModel, super.key});

  final AuthViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final brand = BrandScope.of(context);
    final user = viewModel.session!.user;

    return Scaffold(
      appBar: AppBar(
        title: Text(brand.appName),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: viewModel.logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hola, ${user.displayName}',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'La sesión está activa. El panel de jornada se implementará en el siguiente hito.',
            ),
          ],
        ),
      ),
    );
  }
}
