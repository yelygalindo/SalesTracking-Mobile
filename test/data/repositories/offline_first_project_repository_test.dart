import 'package:flutter_test/flutter_test.dart';
import 'package:urbantrack/data/models/project/project_detail.dart';
import 'package:urbantrack/data/models/project/project_input.dart';
import 'package:urbantrack/data/models/project/project_page.dart';
import 'package:urbantrack/data/models/project/project_summary.dart';
import 'package:urbantrack/data/models/project/project_status.dart';
import 'package:urbantrack/data/repositories/offline_first_project_repository.dart';
import 'package:urbantrack/data/repositories/project_local_store.dart';
import 'package:urbantrack/data/repositories/project_repository.dart';
import 'package:urbantrack/data/services/api_exception.dart';
import 'package:urbantrack/data/services/network_status_service.dart';

void main() {
  test('caches listed projects and exposes their details offline', () async {
    final network = _MutableNetworkStatusService(true);
    final local = _MemoryProjectLocalStore();
    final repository = OfflineFirstProjectRepository(
      _ProjectRemoteRepository(),
      local,
      network,
    );

    final online = await repository.getProjects();
    expect(online.projects.single.name, 'Obra Norte');
    expect(local.projects, hasLength(1));

    network.connected = false;
    final offline = await repository.getProjects(
      status: 'Activo',
      customerId: 'customer-id',
    );
    final detail = await repository.getProject('project-id');

    expect(offline.projects.single.externalId, 'project-id');
    expect(detail.customerName, 'Constructora Horizonte');
    expect(detail.latitude, -17.75);
  });

  test('falls back to cache after a transient remote failure', () async {
    final local = _MemoryProjectLocalStore()..projects.add(_summary);
    final repository = OfflineFirstProjectRepository(
      _ProjectRemoteRepository(failTransiently: true),
      local,
      _MutableNetworkStatusService(true),
    );

    final page = await repository.getProjects();

    expect(page.projects.single.name, 'Obra Norte');
  });

  test('caches the project status catalog for offline use', () async {
    final network = _MutableNetworkStatusService(true);
    final local = _MemoryProjectLocalStore();
    final repository = OfflineFirstProjectRepository(
      _ProjectRemoteRepository(),
      local,
      network,
    );

    final online = await repository.getStatuses();
    expect(online.single.label, 'Activo');
    expect(local.statuses.single.value, 2);

    network.connected = false;
    final offline = await repository.getStatuses();
    expect(offline.single.toJson(), {'value': 2, 'label': 'Activo'});
  });

  test('requires connectivity for project mutations', () async {
    final repository = OfflineFirstProjectRepository(
      _ProjectRemoteRepository(),
      _MemoryProjectLocalStore(),
      _MutableNetworkStatusService(false),
    );

    expect(
      () => repository.createProject(_input, 'request-id'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          contains('conexión'),
        ),
      ),
    );
  });

  test('project models serialize cache payloads symmetrically', () {
    final summary = ProjectSummary.fromJson(_summary.toJson());
    final detail = ProjectDetail.fromJson(_detail.toJson());
    final status = ProjectStatus.fromJson(
      const ProjectStatus(value: 2, label: 'Activo').toJson(),
    );

    expect(summary.externalId, _summary.externalId);
    expect(summary.startDateUtc, _summary.startDateUtc);
    expect(detail.externalId, _detail.externalId);
    expect(detail.expectedCloseDateUtc, _detail.expectedCloseDateUtc);
    expect(status.value, 2);
    expect(status.label, 'Activo');
  });
}

class _MutableNetworkStatusService implements NetworkStatusService {
  _MutableNetworkStatusService(this.connected);

  bool connected;

  @override
  Future<bool> get isConnected async => connected;

  @override
  Stream<bool> get changes => const Stream.empty();
}

class _MemoryProjectLocalStore implements ProjectLocalStore {
  final List<ProjectSummary> projects = [];
  final Map<String, ProjectDetail> details = {};
  final List<ProjectStatus> statuses = [];

  @override
  Future<void> cacheStatuses(List<ProjectStatus> values) async {
    statuses
      ..clear()
      ..addAll(values);
  }

  @override
  Future<void> cacheProjects(List<ProjectSummary> values) async {
    for (final project in values) {
      projects.removeWhere((item) => item.externalId == project.externalId);
      projects.add(project);
      details[project.externalId] = ProjectDetail.fromJson(project.toJson());
    }
  }

  @override
  Future<void> cacheDetail(ProjectDetail project) async {
    details[project.externalId] = project;
    projects.removeWhere((item) => item.externalId == project.externalId);
    projects.add(ProjectSummary.fromJson(project.toJson()));
  }

  @override
  Future<ProjectDetail?> readDetail(String externalId) async =>
      details[externalId];

  @override
  Future<List<ProjectStatus>> readStatuses() async =>
      List.unmodifiable(statuses);

  @override
  Future<ProjectPage> readProjects({
    String? status,
    String? customerId,
    String? sellerId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final filtered = projects
        .where((project) {
          final matchesStatus =
              status == null ||
              project.status.toLowerCase() == status.toLowerCase();
          final matchesCustomer =
              customerId == null || project.customerExternalId == customerId;
          final matchesSeller =
              sellerId == null || project.sellerExternalId == sellerId;
          return matchesStatus && matchesCustomer && matchesSeller;
        })
        .toList(growable: false);
    return ProjectPage(
      projects: filtered,
      page: page,
      pageSize: pageSize,
      totalItems: filtered.length,
      totalPages: filtered.isEmpty ? 0 : 1,
    );
  }
}

class _ProjectRemoteRepository implements ProjectRepository {
  _ProjectRemoteRepository({this.failTransiently = false});

  final bool failTransiently;

  @override
  Future<ProjectPage> getProjects({
    String? status,
    String? customerId,
    String? sellerId,
    int page = 1,
    int pageSize = 20,
  }) async {
    if (failTransiently) {
      throw const ApiException(message: 'No hay conexión a Internet.');
    }
    return ProjectPage(
      projects: [_summary],
      page: page,
      pageSize: pageSize,
      totalItems: 1,
      totalPages: 1,
    );
  }

  @override
  Future<ProjectDetail> getProject(String externalId) async => _detail;

  @override
  Future<List<ProjectStatus>> getStatuses() async => const [
    ProjectStatus(value: 2, label: 'Activo'),
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

const _input = ProjectInput(
  name: 'Obra Norte',
  description: 'Edificio residencial',
  customerExternalId: 'customer-id',
  sellerExternalId: 'seller-id',
  estimatedAmount: 185000,
  startDateUtc: null,
  expectedCloseDateUtc: null,
  progressPercentage: 45,
  actualCloseDateUtc: null,
  address: 'Av. Banzer',
  latitude: -17.75,
  longitude: -63.18,
);

final _summary = ProjectSummary(
  id: 4,
  externalId: 'project-id',
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
  createdAtUtc: DateTime.utc(2026, 8, 1, 12),
);

final _detail = ProjectDetail.fromJson(_summary.toJson());
