import 'package:flutter/foundation.dart';

import '../../data/models/project/project_detail.dart';
import '../../data/models/project/project_status.dart';
import '../../data/repositories/project_repository.dart';
import '../../data/services/api_exception.dart';

enum ProjectDetailViewStatus { initial, loading, ready }

class ProjectDetailViewModel extends ChangeNotifier {
  ProjectDetailViewModel(this._repository, this.externalId);

  final ProjectRepository _repository;
  final String externalId;

  ProjectDetailViewStatus _status = ProjectDetailViewStatus.initial;
  ProjectDetail? _project;
  List<ProjectStatus> _statusOptions = const [];
  String? _errorMessage;
  bool _changingStatus = false;

  ProjectDetailViewStatus get status => _status;
  ProjectDetail? get project => _project;
  List<ProjectStatus> get statusOptions => _statusOptions;
  String? get errorMessage => _errorMessage;
  bool get changingStatus => _changingStatus;

  Future<void> load() async {
    _status = ProjectDetailViewStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final statusesFuture = _repository.getStatuses().catchError(
        (_) => <ProjectStatus>[],
      );
      final results = await Future.wait<Object?>([
        _repository.getProject(externalId),
        statusesFuture,
      ]);
      _project = results[0] as ProjectDetail;
      _statusOptions = results[1] as List<ProjectStatus>;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'No pudimos consultar la obra.';
    }
    _status = ProjectDetailViewStatus.ready;
    notifyListeners();
  }

  Future<bool> changeStatus(ProjectStatus status) async {
    final current = _project;
    if (current == null ||
        _changingStatus ||
        current.status.trim().toLowerCase() == status.label.toLowerCase()) {
      return false;
    }
    _changingStatus = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.changeStatus(externalId, status.value);
      _project = await _repository.getProject(externalId);
      _changingStatus = false;
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'No pudimos cambiar el estado de la obra.';
    }
    _changingStatus = false;
    notifyListeners();
    return false;
  }
}
