import 'package:flutter/foundation.dart';

import '../../data/models/project/project_detail.dart';
import '../../data/repositories/project_repository.dart';
import '../../data/services/api_exception.dart';

enum ProjectDetailViewStatus { initial, loading, ready }

class ProjectDetailViewModel extends ChangeNotifier {
  ProjectDetailViewModel(this._repository, this.externalId);

  final ProjectRepository _repository;
  final String externalId;

  ProjectDetailViewStatus _status = ProjectDetailViewStatus.initial;
  ProjectDetail? _project;
  String? _errorMessage;

  ProjectDetailViewStatus get status => _status;
  ProjectDetail? get project => _project;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _status = ProjectDetailViewStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _project = await _repository.getProject(externalId);
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'No pudimos consultar la obra.';
    }
    _status = ProjectDetailViewStatus.ready;
    notifyListeners();
  }
}
