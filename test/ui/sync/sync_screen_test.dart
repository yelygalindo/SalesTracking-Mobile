import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urbantrack/data/models/sync/sync_queue_entry.dart';
import 'package:urbantrack/data/repositories/sync_repository.dart';
import 'package:urbantrack/data/services/network_status_service.dart';
import 'package:urbantrack/ui/core/branding/brand_scope.dart';
import 'package:urbantrack/ui/core/branding/urbantrack_brand.dart';
import 'package:urbantrack/ui/sync/sync_screen.dart';
import 'package:urbantrack/ui/sync/sync_view_model.dart';

void main() {
  testWidgets('shows and retries the queue on a narrow screen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _ScreenSyncRepository();
    final viewModel = SyncViewModel(
      repository,
      const _ConnectedNetworkStatusService(),
    );
    await viewModel.initialize();

    await tester.pumpWidget(
      BrandScope(
        brand: UrbanTrackBrand.config,
        child: MaterialApp(home: SyncScreen(viewModel: viewModel)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2 registros pendientes'), findsOneWidget);
    expect(find.text('Inicio de jornada'), findsOneWidget);
    expect(find.text('Cierre de jornada'), findsOneWidget);
    expect(find.text('Intentar sincronizar ahora'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Intentar sincronizar ahora'));
    await tester.pumpAndSettle();

    expect(find.text('Todo está sincronizado'), findsOneWidget);
    expect(repository.syncCalls, 1);
    viewModel.dispose();
  });
}

class _ScreenSyncRepository implements SyncRepository {
  var syncCalls = 0;
  var items = [
    SyncQueueEntry(
      id: 'start-id',
      type: SyncQueueEntryType.workdayStart,
      occurredAtUtc: DateTime.utc(2026, 8, 7, 15),
      createdAtUtc: DateTime.utc(2026, 8, 7, 15, 0, 1),
      attemptCount: 0,
    ),
    SyncQueueEntry(
      id: 'close-id',
      type: SyncQueueEntryType.workdayClose,
      occurredAtUtc: DateTime.utc(2026, 8, 7, 22),
      createdAtUtc: DateTime.utc(2026, 8, 7, 22, 0, 1),
      dependsOnId: 'start-id',
      attemptCount: 0,
    ),
  ];

  @override
  Future<List<SyncQueueEntry>> getPending() async => List.unmodifiable(items);

  @override
  Future<void> synchronize() async {
    syncCalls += 1;
    items = [];
  }
}

class _ConnectedNetworkStatusService implements NetworkStatusService {
  const _ConnectedNetworkStatusService();

  @override
  Future<bool> get isConnected async => true;

  @override
  Stream<bool> get changes => const Stream.empty();
}
