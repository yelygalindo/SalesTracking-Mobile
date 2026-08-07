import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urbantrack/data/models/history/project_visit.dart';
import 'package:urbantrack/data/models/history/seller_timeline_item.dart';
import 'package:urbantrack/data/models/history/seller_timeline_page.dart';
import 'package:urbantrack/data/repositories/history_repository.dart';
import 'package:urbantrack/ui/core/branding/brand_scope.dart';
import 'package:urbantrack/ui/core/branding/urbantrack_brand.dart';
import 'package:urbantrack/ui/history/history_screen.dart';
import 'package:urbantrack/ui/history/project_visits_screen.dart';

void main() {
  testWidgets('renders personal history without overflow on a phone', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _HistoryScreenRepository();

    await tester.pumpWidget(
      BrandScope(
        brand: UrbanTrackBrand.config,
        child: MaterialApp(home: HistoryScreen(repository: repository)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Todo lo que registraste'), findsOneWidget);
    expect(find.text('Visita finalizada · Obra Norte'), findsOneWidget);
    expect(find.text('Jornada iniciada'), findsOneWidget);
    expect(find.text('Historial'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders project visit results on a narrow screen', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      BrandScope(
        brand: UrbanTrackBrand.config,
        child: MaterialApp(
          home: ProjectVisitsScreen(
            repository: _HistoryScreenRepository(),
            projectExternalId: 'project-id',
            projectName: 'Obra Norte',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Visitas registradas'), findsOneWidget);
    expect(find.text('Cotización entregada'), findsOneWidget);
    expect(find.text('Revisar precios el viernes'), findsOneWidget);
    expect(find.text('Cerrada'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _HistoryScreenRepository implements HistoryRepository {
  @override
  Future<SellerTimelinePage> getMyTimeline({
    DateTime? from,
    DateTime? to,
    int page = 1,
    int pageSize = 30,
  }) async => SellerTimelinePage(
    items: [
      SellerTimelineItem(
        externalId: 'event-1',
        eventType: 'ProjectVisitCheckedOut',
        resourceType: 'ProjectVisit',
        resourceExternalId: 'visit-id',
        title: 'Visita finalizada · Obra Norte',
        description: 'Resultado: seguimiento realizado · 3 fotos.',
        occurredAtUtc: DateTime.utc(2026, 8, 4, 11),
      ),
      SellerTimelineItem(
        externalId: 'event-2',
        eventType: 'WorkdayStarted',
        resourceType: 'Workday',
        resourceExternalId: 'workday-id',
        title: 'Jornada iniciada',
        description: '',
        occurredAtUtc: DateTime.utc(2026, 8, 4, 8),
      ),
    ],
    page: 1,
    pageSize: pageSize,
    totalItems: 2,
    totalPages: 1,
  );

  @override
  Future<List<ProjectVisit>> getProjectVisits(
    String projectExternalId, {
    String? sellerExternalId,
    DateTime? from,
    DateTime? to,
  }) async => [
    ProjectVisit(
      externalId: 'visit-id',
      projectExternalId: projectExternalId,
      projectName: 'Obra Norte',
      customerExternalId: 'customer-id',
      customerName: 'Constructora Horizonte',
      visitedAtUtc: DateTime.utc(2026, 8, 3, 14, 10),
      latitude: -17.7833,
      longitude: -63.1821,
      notes: 'Revisar avance',
      checkOutAtUtc: DateTime.utc(2026, 8, 3, 15, 5),
      checkOutLatitude: -17.7834,
      checkOutLongitude: -63.1822,
      checkOutNote: 'Revisar precios el viernes',
      result: 'Cotización entregada',
      sellerExternalId: 'seller-id',
      sellerName: 'Carlos Gómez',
    ),
  ];
}
