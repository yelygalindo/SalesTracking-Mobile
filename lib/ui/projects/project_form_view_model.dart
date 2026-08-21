import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/common/location_sample.dart';
import '../../data/models/customer/customer_summary.dart';
import '../../data/models/customer/customer_page.dart';
import '../../data/models/project/project_detail.dart';
import '../../data/models/project/project_input.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/project_repository.dart';
import '../../data/services/api_exception.dart';
import '../../data/services/location_service.dart';

enum ProjectFormViewStatus { initial, loading, ready, locating, saving }

class ProjectFormViewModel extends ChangeNotifier {
  ProjectFormViewModel(
    this._projects,
    this._customers,
    this._locationService, {
    this.externalId,
    String Function()? requestId,
  }) : _requestId = requestId ?? const Uuid().v4;

  final ProjectRepository _projects;
  final CustomerRepository _customers;
  final LocationService _locationService;
  final String? externalId;
  final String Function() _requestId;

  ProjectFormViewStatus _status = ProjectFormViewStatus.initial;
  ProjectDetail? _project;
  List<CustomerSummary> _customerOptions = const [];
  LocationSample? _location;
  String? _errorMessage;
  String? _savedExternalId;

  ProjectFormViewStatus get status => _status;
  ProjectDetail? get project => _project;
  List<CustomerSummary> get customerOptions => _customerOptions;
  LocationSample? get location => _location;
  String? get errorMessage => _errorMessage;
  String? get savedExternalId => _savedExternalId;
  bool get editing => externalId != null;
  bool get canSave => !editing || _project?.updatedAtUtcToken != null;
  bool get isBusy =>
      _status == ProjectFormViewStatus.loading ||
      _status == ProjectFormViewStatus.locating ||
      _status == ProjectFormViewStatus.saving;

  Future<void> initialize() async {
    _status = ProjectFormViewStatus.loading;
    _errorMessage = null;
    if (editing) _project = null;
    notifyListeners();
    try {
      final customersFuture = _customers.getCustomers(pageSize: 100);
      final projectFuture = editing
          ? _projects.getProject(externalId!, requireFresh: true)
          : Future<ProjectDetail?>.value();
      final results = await Future.wait<Object?>([
        customersFuture,
        projectFuture,
      ]);
      final project = results[1] as ProjectDetail?;
      if (editing && project?.updatedAtUtcToken == null) {
        throw const ApiException(
          message:
              'No pudimos obtener la versión actual de la obra. Reintenta antes de editar.',
        );
      }
      _customerOptions = (results[0] as CustomerPage).customers;
      _project = project;
      if (project?.latitude != null && project?.longitude != null) {
        _location = LocationSample(
          latitude: project!.latitude!,
          longitude: project.longitude!,
          accuracyMeters: 0,
        );
      }
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'No pudimos preparar el formulario de obra.';
    }
    _status = ProjectFormViewStatus.ready;
    notifyListeners();
  }

  Future<bool> captureLocation() async {
    _status = ProjectFormViewStatus.locating;
    _errorMessage = null;
    notifyListeners();
    try {
      _location = await _locationService.captureCurrent();
      _status = ProjectFormViewStatus.ready;
      notifyListeners();
      return true;
    } on LocationFailure catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'No pudimos obtener la ubicación.';
    }
    _status = ProjectFormViewStatus.ready;
    notifyListeners();
    return false;
  }

  Future<bool> save({
    required String name,
    required String description,
    required String? customerExternalId,
    required double? estimatedAmount,
    required DateTime? startDateUtc,
    required DateTime? expectedCloseDateUtc,
    required double? progressPercentage,
    required String address,
  }) async {
    if (!canSave) {
      _errorMessage =
          'No pudimos obtener la versión actual de la obra. Recarga los datos antes de guardar.';
      notifyListeners();
      return false;
    }
    if (name.trim().isEmpty || customerExternalId == null) {
      _errorMessage = 'Completa el nombre y selecciona un cliente.';
      notifyListeners();
      return false;
    }
    if (progressPercentage != null &&
        (progressPercentage < 0 || progressPercentage > 100)) {
      _errorMessage = 'El avance debe estar entre 0 y 100.';
      notifyListeners();
      return false;
    }
    final input = ProjectInput(
      name: name,
      description: description,
      customerExternalId: customerExternalId,
      sellerExternalId: _project?.sellerExternalId,
      estimatedAmount: estimatedAmount,
      startDateUtc: startDateUtc,
      expectedCloseDateUtc: expectedCloseDateUtc,
      progressPercentage: progressPercentage,
      actualCloseDateUtc: _project?.actualCloseDateUtc,
      address: address,
      latitude: _location?.latitude,
      longitude: _location?.longitude,
      expectedUpdatedAtUtc: _project?.updatedAtUtc,
      expectedUpdatedAtUtcToken: _project?.updatedAtUtcToken,
    );
    _status = ProjectFormViewStatus.saving;
    _errorMessage = null;
    notifyListeners();
    try {
      if (editing) {
        await _projects.updateProject(externalId!, input);
        _savedExternalId = externalId;
      } else {
        final created = await _projects.createProject(input, _requestId());
        if (created.externalId.isEmpty) {
          throw const ApiException(
            message: 'El servidor no devolvió el ID de la obra.',
          );
        }
        _savedExternalId = created.externalId;
      }
      _status = ProjectFormViewStatus.ready;
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'No pudimos guardar la obra.';
    }
    _status = ProjectFormViewStatus.ready;
    notifyListeners();
    return false;
  }
}
