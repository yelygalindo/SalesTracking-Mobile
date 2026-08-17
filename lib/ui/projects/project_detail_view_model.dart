import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/project/project_detail.dart';
import '../../data/models/project/project_note.dart';
import '../../data/models/project/project_reminder.dart';
import '../../data/models/project/project_status.dart';
import '../../data/models/project/project_timeline_item.dart';
import '../../data/models/project/project_timeline_page.dart';
import '../../data/repositories/project_repository.dart';
import '../../data/services/api_exception.dart';

enum ProjectDetailViewStatus { initial, loading, ready }

class ProjectDetailViewModel extends ChangeNotifier {
  ProjectDetailViewModel(
    this._repository,
    this.externalId, {
    String Function()? requestId,
    DateTime Function()? now,
  }) : _requestId = requestId ?? const Uuid().v4,
       _now = now ?? DateTime.now;

  final ProjectRepository _repository;
  final String externalId;
  final String Function() _requestId;
  final DateTime Function() _now;

  ProjectDetailViewStatus _status = ProjectDetailViewStatus.initial;
  ProjectDetail? _project;
  List<ProjectStatus> _statusOptions = const [];
  List<ProjectNote> _notes = const [];
  List<ProjectReminder> _reminders = const [];
  List<ProjectTimelineItem> _timeline = const [];
  String? _errorMessage;
  String? _activityErrorMessage;
  bool _changingStatus = false;
  bool _loadingActivity = false;
  bool _savingNote = false;
  bool _savingReminder = false;

  ProjectDetailViewStatus get status => _status;
  ProjectDetail? get project => _project;
  List<ProjectStatus> get statusOptions => _statusOptions;
  List<ProjectNote> get notes => _notes;
  List<ProjectReminder> get reminders => _reminders;
  List<ProjectTimelineItem> get timeline => _timeline;
  String? get errorMessage => _errorMessage;
  String? get activityErrorMessage => _activityErrorMessage;
  bool get changingStatus => _changingStatus;
  bool get loadingActivity => _loadingActivity;
  bool get savingNote => _savingNote;
  bool get savingReminder => _savingReminder;

  Future<void> load() async {
    _status = ProjectDetailViewStatus.loading;
    _errorMessage = null;
    _loadingActivity = true;
    notifyListeners();
    try {
      final statusesFuture = _repository.getStatuses().catchError(
        (_) => <ProjectStatus>[],
      );
      final results = await Future.wait<Object?>([
        _repository.getProject(externalId),
        statusesFuture,
        _loadActivity(),
      ]);
      _project = results[0] as ProjectDetail;
      _statusOptions = results[1] as List<ProjectStatus>;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'No pudimos consultar la obra.';
    }
    _loadingActivity = false;
    _status = ProjectDetailViewStatus.ready;
    notifyListeners();
  }

  Future<void> reloadActivity() async {
    if (_loadingActivity) return;
    _loadingActivity = true;
    notifyListeners();
    await _loadActivity();
    _loadingActivity = false;
    notifyListeners();
  }

  Future<bool> addNote(String content) async {
    final normalized = content.trim();
    if (normalized.isEmpty) {
      _activityErrorMessage = 'Escribe una nota antes de guardarla.';
      notifyListeners();
      return false;
    }
    if (_savingNote) return false;
    _savingNote = true;
    _activityErrorMessage = null;
    notifyListeners();
    try {
      await _repository.addNote(
        externalId,
        content: normalized,
        clientRequestId: _requestId(),
        occurredAtUtc: _now().toUtc(),
      );
      await _loadActivity();
      _savingNote = false;
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      _activityErrorMessage = error.message;
    } catch (_) {
      _activityErrorMessage = 'No pudimos agregar la nota a esta obra.';
    }
    _savingNote = false;
    notifyListeners();
    return false;
  }

  Future<bool> addReminder({
    required String text,
    required DateTime reminderAtUtc,
  }) async {
    final normalized = text.trim();
    if (normalized.isEmpty) {
      _activityErrorMessage = 'Escribe un recordatorio antes de guardarlo.';
      notifyListeners();
      return false;
    }
    if (_savingReminder) return false;
    _savingReminder = true;
    _activityErrorMessage = null;
    notifyListeners();
    try {
      await _repository.addReminder(
        externalId,
        text: normalized,
        reminderAtUtc: reminderAtUtc.toUtc(),
      );
      await _loadActivity();
      _savingReminder = false;
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      _activityErrorMessage = error.message;
    } catch (_) {
      _activityErrorMessage = 'No pudimos agregar el recordatorio a esta obra.';
    }
    _savingReminder = false;
    notifyListeners();
    return false;
  }

  Future<bool> completeReminder(String reminderExternalId) async {
    if (_savingReminder) return false;
    _savingReminder = true;
    _activityErrorMessage = null;
    notifyListeners();
    try {
      await _repository.completeReminder(externalId, reminderExternalId);
      await _loadActivity();
      _savingReminder = false;
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      _activityErrorMessage = error.message;
    } catch (_) {
      _activityErrorMessage =
          'No pudimos completar el recordatorio de esta obra.';
    }
    _savingReminder = false;
    notifyListeners();
    return false;
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

  Future<void> _loadActivity() async {
    _activityErrorMessage = null;
    try {
      final results = await Future.wait<Object>([
        _repository.getNotes(externalId),
        _repository.getReminders(externalId, completed: false),
        _repository.getTimeline(externalId),
      ]);
      _notes = results[0] as List<ProjectNote>;
      _reminders = results[1] as List<ProjectReminder>;
      _timeline = (results[2] as ProjectTimelinePage).items;
    } on ApiException catch (error) {
      _activityErrorMessage = error.message;
    } catch (_) {
      _activityErrorMessage = 'No pudimos consultar la actividad de la obra.';
    }
  }
}
