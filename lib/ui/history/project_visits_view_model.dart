import 'package:flutter/foundation.dart';

import '../../data/models/attachment/project_attachment.dart';
import '../../data/models/history/project_visit.dart';
import '../../data/repositories/history_repository.dart';
import '../../data/services/api_exception.dart';

enum ProjectVisitsStatus { initial, loading, loaded, failed }

class ProjectVisitsViewModel extends ChangeNotifier {
  ProjectVisitsViewModel(this._repository, this._projectExternalId);

  final HistoryRepository _repository;
  final String _projectExternalId;

  ProjectVisitsStatus _status = ProjectVisitsStatus.initial;
  List<ProjectVisit> _visits = const [];
  final Map<String, List<ProjectAttachment>> _attachmentsByVisit = {};
  String? _errorMessage;

  ProjectVisitsStatus get status => _status;
  List<ProjectVisit> get visits => _visits;
  String? get errorMessage => _errorMessage;
  List<ProjectAttachment> attachmentsFor(ProjectVisit visit) =>
      _attachmentsByVisit[visit.externalId] ?? const [];

  Future<void> load() async {
    _status = ProjectVisitsStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _visits = await _repository.getProjectVisits(_projectExternalId);
      _attachmentsByVisit.clear();
      await Future.wait(
        _visits.map((visit) async {
          try {
            _attachmentsByVisit[visit.externalId] = await _repository
                .getVisitAttachments(visit.externalId);
          } catch (_) {
            // La visita sigue siendo útil aunque sus miniaturas no estén.
            _attachmentsByVisit[visit.externalId] = const [];
          }
        }),
      );
      _status = ProjectVisitsStatus.loaded;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      _status = ProjectVisitsStatus.failed;
    } catch (_) {
      _errorMessage = 'No pudimos cargar las visitas de esta obra.';
      _status = ProjectVisitsStatus.failed;
    }
    notifyListeners();
  }
}
