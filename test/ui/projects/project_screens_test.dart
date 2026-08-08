import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urbantrack/data/models/project/project_detail.dart';
import 'package:urbantrack/data/models/project/project_input.dart';
import 'package:urbantrack/data/models/project/project_page.dart';
import 'package:urbantrack/data/models/project/project_summary.dart';
import 'package:urbantrack/data/models/project/project_status.dart';
import 'package:urbantrack/data/repositories/project_repository.dart';
import 'package:urbantrack/ui/core/branding/brand_scope.dart';
import 'package:urbantrack/ui/core/branding/urbantrack_brand.dart';
import 'package:urbantrack/ui/projects/project_detail_screen.dart';
import 'package:urbantrack/ui/projects/project_form_screen.dart';
import 'package:urbantrack/ui/projects/project_list_screen.dart';

import '../../support/workday_test_doubles.dart';

void main() {
  testWidgets('renders the project list on phone and tablet', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      BrandScope(
        brand: UrbanTrackBrand.config,
        child: MaterialApp(
          home: ProjectListScreen(
            projectRepository: _ProjectScreenRepository(),
            customerRepository: EmptyCustomerRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Obra Norte'), findsOneWidget);
    expect(find.text('Avance 45%'), findsNWidgets(2));
    expect(find.text('Estado'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.binding.setSurfaceSize(const Size(1024, 900));
    await tester.pumpAndSettle();
    expect(find.text('Residencial Sur'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders project detail and responsive form', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1024, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _ProjectScreenRepository();

    await tester.pumpWidget(
      BrandScope(
        brand: UrbanTrackBrand.config,
        child: MaterialApp(
          home: ProjectDetailScreen(
            repository: repository,
            visitRepository: EmptyVisitRepository(),
            externalId: 'project-1',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Editar obra'), findsOneWidget);
    expect(find.text('Cambiar estado'), findsOneWidget);
    expect(find.text('Bs 185000.00'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Cambiar estado'));
    await tester.pumpAndSettle();
    expect(find.text('Cambiar estado de la obra'), findsOneWidget);
    expect(find.text('Borrador'), findsOneWidget);
    expect(find.text('En pausa'), findsOneWidget);
    expect(find.text('Cancelado'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Cancelado'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      MaterialApp(
        home: ProjectFormScreen(
          projectRepository: repository,
          customerRepository: EmptyCustomerRepository(),
          locationService: FixedLocationService(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Registrar obra'), findsOneWidget);
    expect(find.text('Usar ubicación actual'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _ProjectScreenRepository implements ProjectRepository {
  @override
  Future<ProjectPage> getProjects({
    String? status,
    String? customerId,
    String? sellerId,
    int page = 1,
    int pageSize = 20,
  }) async => ProjectPage(
    projects: [_summary(1, 'Obra Norte'), _summary(2, 'Residencial Sur')],
    page: 1,
    pageSize: pageSize,
    totalItems: 2,
    totalPages: 1,
  );

  @override
  Future<ProjectDetail> getProject(String externalId) async => _detail;

  @override
  Future<List<ProjectStatus>> getStatuses() async => const [
    ProjectStatus(value: 1, label: 'Borrador'),
    ProjectStatus(value: 2, label: 'Activo'),
    ProjectStatus(value: 3, label: 'En pausa'),
    ProjectStatus(value: 4, label: 'Completado'),
    ProjectStatus(value: 5, label: 'Cancelado'),
  ];

  @override
  Future<ProjectDetail> createProject(
    ProjectInput input,
    String clientRequestId,
  ) async => _detail;

  @override
  Future<void> updateProject(String externalId, ProjectInput input) async {}

  @override
  Future<void> changeStatus(String externalId, int statusId) async {}
}

ProjectSummary _summary(int id, String name) => ProjectSummary(
  id: id,
  externalId: 'project-$id',
  name: name,
  description: '',
  customerExternalId: 'customer-id',
  customerName: 'Constructora Horizonte',
  sellerExternalId: 'seller-id',
  sellerName: 'Carlos Gómez',
  status: 'Activo',
  estimatedAmount: 185000,
  startDateUtc: DateTime.utc(2026, 8, 1),
  expectedCloseDateUtc: DateTime.utc(2026, 10, 30),
  progressPercentage: 45,
  actualCloseDateUtc: null,
  address: 'Av. Banzer',
  latitude: -17.75,
  longitude: -63.18,
  createdAtUtc: DateTime.utc(2026, 8, 1),
);

final _detail = ProjectDetail(
  id: 1,
  externalId: 'project-1',
  name: 'Obra Norte',
  description: 'Edificio residencial',
  customerExternalId: 'customer-id',
  customerName: 'Constructora Horizonte',
  sellerExternalId: 'seller-id',
  sellerName: 'Carlos Gómez',
  status: 'Activo',
  estimatedAmount: 185000,
  startDateUtc: DateTime.utc(2026, 8, 1),
  expectedCloseDateUtc: DateTime.utc(2026, 10, 30),
  progressPercentage: 45,
  actualCloseDateUtc: null,
  address: 'Av. Banzer',
  latitude: -17.75,
  longitude: -63.18,
  createdAtUtc: DateTime.utc(2026, 8, 1),
);
