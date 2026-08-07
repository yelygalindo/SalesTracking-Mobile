import '../models/project/project_detail.dart';
import '../models/project/project_input.dart';
import '../models/project/project_page.dart';
import '../services/api_exception.dart';
import '../services/network_status_service.dart';
import 'project_local_store.dart';
import 'project_repository.dart';

class OfflineFirstProjectRepository implements ProjectRepository {
  const OfflineFirstProjectRepository(this._remote, this._local, this._network);

  final ProjectRepository _remote;
  final ProjectLocalStore _local;
  final NetworkStatusService _network;

  @override
  Future<ProjectPage> getProjects({
    String? status,
    String? customerId,
    String? sellerId,
    int page = 1,
    int pageSize = 20,
  }) async {
    if (await _network.isConnected) {
      try {
        final remotePage = await _remote.getProjects(
          status: status,
          customerId: customerId,
          sellerId: sellerId,
          page: page,
          pageSize: pageSize,
        );
        await _local.cacheProjects(remotePage.projects);
        return remotePage;
      } on ApiException catch (error) {
        if (!_isTransient(error)) rethrow;
      }
    }
    return _local.readProjects(
      status: status,
      customerId: customerId,
      sellerId: sellerId,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<ProjectDetail> getProject(String externalId) async {
    if (await _network.isConnected) {
      try {
        final project = await _remote.getProject(externalId);
        await _local.cacheDetail(project);
        return project;
      } on ApiException catch (error) {
        if (!_isTransient(error)) rethrow;
      }
    }
    final cached = await _local.readDetail(externalId);
    if (cached != null) return cached;
    throw const ApiException(
      message: 'Esta obra todavía no está disponible sin conexión.',
    );
  }

  @override
  Future<ProjectDetail> createProject(
    ProjectInput input,
    String clientRequestId,
  ) async {
    await _requireConnection('Necesitas conexión para registrar una obra.');
    final project = await _remote.createProject(input, clientRequestId);
    await _local.cacheDetail(project);
    return project;
  }

  @override
  Future<void> updateProject(String externalId, ProjectInput input) async {
    await _requireConnection('Necesitas conexión para editar esta obra.');
    await _remote.updateProject(externalId, input);
    final refreshed = await _remote.getProject(externalId);
    await _local.cacheDetail(refreshed);
  }

  @override
  Future<void> changeStatus(String externalId, int statusId) async {
    await _requireConnection(
      'Necesitas conexión para cambiar el estado de la obra.',
    );
    await _remote.changeStatus(externalId, statusId);
    final refreshed = await _remote.getProject(externalId);
    await _local.cacheDetail(refreshed);
  }

  Future<void> _requireConnection(String message) async {
    if (!await _network.isConnected) throw ApiException(message: message);
  }

  bool _isTransient(ApiException error) {
    final status = error.statusCode;
    return status == null || status == 408 || status == 429 || status >= 500;
  }
}
