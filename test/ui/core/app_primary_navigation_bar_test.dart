import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:urbantrack/routing/app_router.dart';
import 'package:urbantrack/ui/core/navigation/app_primary_navigation_bar.dart';

void main() {
  testWidgets('navigates between primary destinations on a phone', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final router = GoRouter(
      initialLocation: AppRoutes.home,
      routes: [
        _route(AppRoutes.home, 'home-page', AppPrimaryDestination.home),
        _route(
          AppRoutes.customers,
          'customers-page',
          AppPrimaryDestination.customers,
        ),
        _route(
          AppRoutes.projects,
          'projects-page',
          AppPrimaryDestination.projects,
        ),
        _route(
          AppRoutes.history,
          'history-page',
          AppPrimaryDestination.history,
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('home-page'), findsOneWidget);
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Clientes'), findsOneWidget);
    expect(find.text('Obras'), findsOneWidget);
    expect(find.text('Historial'), findsOneWidget);

    await tester.tap(find.text('Clientes'));
    await tester.pumpAndSettle();

    expect(find.text('customers-page'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

GoRoute _route(String path, String label, AppPrimaryDestination destination) =>
    GoRoute(
      path: path,
      builder: (context, state) => Scaffold(
        body: Center(child: Text(label)),
        bottomNavigationBar: AppPrimaryNavigationBar(selected: destination),
      ),
    );
