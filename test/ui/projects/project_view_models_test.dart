import 'package:flutter_test/flutter_test.dart';
import 'package:urbantrack/data/models/common/location_sample.dart';
import 'package:urbantrack/data/models/common/resource_creation_result.dart';
import 'package:urbantrack/data/models/customer/customer_detail.dart';
import 'package:urbantrack/data/models/customer/customer_input.dart';
import 'package:urbantrack/data/models/customer/customer_page.dart';
import 'package:urbantrack/data/models/customer/customer_status.dart';
import 'package:urbantrack/data/models/customer/customer_summary.dart';
import 'package:urbantrack/data/models/project/project_detail.dart';
import 'package:urbantrack/data/models/project/project_input.dart';
import 'package:urbantrack/data/models/project/project_page.dart';
import 'package:urbantrack/data/models/project/project_status.dart';
import 'package:urbantrack/data/models/project/project_summary.dart';
import 'package:urbantrack/data/repositories/customer_repository.dart';
import 'package:urbantrack/data/repositories/project_repository.dart';
import 'package:urbantrack/data/services/location_service.dart';
import 'package:urbantrack/ui/projects/project_detail_view_model.dart';
import 'package:urbantrack/ui/projects/project_form_view_model.dart';
import 'package:urbantrack/ui/projects/project_list_view_model.dart';

void main() {
  test('filters and paginates the project list', () async {
    final projects = _RecordingProjectRepository();
    final viewModel = ProjectListViewModel(
      projects,
      _CustomerOptionsRepository(),
      pageSize: 1,
    );

    await viewModel.initialize();
    await viewModel.selectStatus('Activo');
    await viewModel.selectCustomer('customer-id');
    await viewModel.loadMore();

    expect(viewModel.customerOptions.single.externalId, 'customer-id');
    expect(projects.statuses.last, 'Activo');
    expect(projects.customerIds.last, 'customer-id');
    expect(viewModel.items.length, 2);
  });

  test('creates a project with GPS and a stable request id', () async {
    final projects = _RecordingProjectRepository();
    final viewModel = ProjectFormViewModel(
      projects,
      _CustomerOptionsRepository(),
      _FixedLocationService(),
      requestId: () => 'project-request-id',
    );
    await viewModel.initialize();
    await viewModel.captureLocation();

    final saved = await viewModel.save(
      name: 'Obra Norte',
      description: 'Edificio residencial',
      customerExternalId: 'customer-id',
      estimatedAmount: 185000,
      startDateUtc: DateTime.utc(2026, 8, 1),
      expectedCloseDateUtc: DateTime.utc(2026, 10, 30),
      progressPercentage: 45,
      address: 'Av. Banzer',
    );

    expect(saved, isTrue);
    expect(projects.createdRequestId, 'project-request-id');
    expect(projects.createdInput?.latitude, -17.75);
    expect(viewModel.savedExternalId, 'project-id');
  });

  test('loads project detail and changes its status', () async {
    final projects = _RecordingProjectRepository();
    final viewModel = ProjectDetailViewModel(projects, 'project-id');

    await viewModel.load();

    expect(viewModel.project?.name, 'Obra Norte');
    expect(viewModel.project?.progressPercentage, 45);
    expect(viewModel.statusOptions.map((status) => status.label), [
      'Activo',
      'Completado',
    ]);

    final changed = await viewModel.changeStatus(
      const ProjectStatus(value: 4, label: 'Completado'),
    );

    expect(changed, isTrue);
    expect(projects.changedStatusId, 4);
    expect(viewModel.project?.status, 'Completado');
  });
}

class _RecordingProjectRepository implements ProjectRepository {
  final List<String?> statuses = [];
  final List<String?> customerIds = [];
  ProjectInput? createdInput;
  String? createdRequestId;
  int? changedStatusId;
  String currentStatus = 'Activo';

  @override
  Future<ProjectPage> getProjects({
    String? status,
    String? customerId,
    String? sellerId,
    int page = 1,
    int pageSize = 20,
  }) async {
    statuses.add(status);
    customerIds.add(customerId);
    return ProjectPage(
      projects: [_summary(page)],
      page: page,
      pageSize: pageSize,
      totalItems: 2,
      totalPages: 2,
    );
  }

  @override
  Future<ProjectDetail> getProject(String externalId) async =>
      ProjectDetail.fromJson({..._detail.toJson(), 'status': currentStatus});

  @override
  Future<List<ProjectStatus>> getStatuses() async => const [
    ProjectStatus(value: 2, label: 'Activo'),
    ProjectStatus(value: 4, label: 'Completado'),
  ];

  @override
  Future<ProjectDetail> createProject(
    ProjectInput input,
    String clientRequestId,
  ) async {
    createdInput = input;
    createdRequestId = clientRequestId;
    return _detail;
  }

  @override
  Future<void> updateProject(String externalId, ProjectInput input) async {}

  @override
  Future<void> changeStatus(String externalId, int statusId) async {
    changedStatusId = statusId;
    currentStatus = switch (statusId) {
      4 => 'Completado',
      _ => currentStatus,
    };
  }
}

class _CustomerOptionsRepository implements CustomerRepository {
  @override
  Future<CustomerPage> getCustomers({
    String? status,
    String? externalUserId,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async => CustomerPage(
    customers: [_customer],
    page: 1,
    pageSize: pageSize,
    totalItems: 1,
    totalPages: 1,
  );

  @override
  Future<List<CustomerStatus>> getStatuses() async => const [];

  @override
  Future<CustomerDetail> getCustomer(String externalId) {
    throw UnimplementedError();
  }

  @override
  Future<ResourceCreationResult> createCustomer(
    CustomerInput input,
    String clientRequestId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateCustomer(String externalId, CustomerInput input) async {}

  @override
  Future<void> changeStatus(String externalId, int statusId) async {}

  @override
  Future<ResourceCreationResult> addNote(
    String externalId,
    String text,
    String clientRequestId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<ResourceCreationResult> addReminder(
    String externalId, {
    required String text,
    required DateTime reminderAtUtc,
    String? assignedToId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> completeReminder(
    String customerExternalId,
    String reminderExternalId,
  ) {
    throw UnimplementedError();
  }
}

class _FixedLocationService implements LocationService {
  @override
  Future<LocationSample> captureCurrent() async => const LocationSample(
    latitude: -17.75,
    longitude: -63.18,
    accuracyMeters: 6,
  );
}

final _customer = CustomerSummary(
  id: 1,
  externalId: 'customer-id',
  name: 'Ricardo',
  companyName: 'Constructora Horizonte',
  phone: '70010001',
  email: 'seller@example.test',
  status: 'Activo',
  createdAtUtc: DateTime.utc(2026, 8, 1),
  seller: null,
);

ProjectSummary _summary(int index) => ProjectSummary(
  id: index,
  externalId: 'project-$index',
  name: 'Obra $index',
  description: '',
  customerExternalId: 'customer-id',
  customerName: 'Constructora Horizonte',
  sellerExternalId: 'seller-id',
  sellerName: 'Carlos',
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
  id: 4,
  externalId: 'project-id',
  name: 'Obra Norte',
  description: 'Edificio residencial',
  customerExternalId: 'customer-id',
  customerName: 'Constructora Horizonte',
  sellerExternalId: 'seller-id',
  sellerName: 'Carlos',
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
