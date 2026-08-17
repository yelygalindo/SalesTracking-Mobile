import 'package:flutter/foundation.dart';

import '../../data/models/attachment/project_attachment.dart';
import '../../data/models/history/seller_timeline_item.dart';
import '../../data/repositories/history_repository.dart';
import '../../data/services/api_exception.dart';

enum HistoryViewStatus { initial, loading, loaded, loadingMore, failed }

class HistoryViewModel extends ChangeNotifier {
  HistoryViewModel(this._repository, {DateTime? initialDate})
    : _selectedDate = _day(initialDate ?? DateTime.now());

  final HistoryRepository _repository;

  HistoryViewStatus _status = HistoryViewStatus.initial;
  DateTime _selectedDate;
  List<SellerTimelineItem> _items = const [];
  final Map<String, List<ProjectAttachment>> _attachmentsByVisit = {};
  Set<String> _photoHostEventIds = const {};
  int _page = 0;
  int _totalPages = 0;
  String? _errorMessage;

  HistoryViewStatus get status => _status;
  DateTime get selectedDate => _selectedDate;
  List<SellerTimelineItem> get items => _items;
  String? get errorMessage => _errorMessage;
  bool get canLoadMore => _page < _totalPages;

  List<ProjectAttachment> attachmentsFor(SellerTimelineItem item) {
    if (!_photoHostEventIds.contains(item.externalId)) return const [];
    return _attachmentsByVisit[item.resourceExternalId] ?? const [];
  }

  Future<void> selectDate(DateTime date) async {
    final normalized = _day(date);
    if (_selectedDate == normalized) return;
    _selectedDate = normalized;
    await load();
  }

  Future<void> load() => _loadPage(1, replace: true);

  Future<void> loadMore() async {
    if (!canLoadMore || _status == HistoryViewStatus.loadingMore) return;
    await _loadPage(_page + 1, replace: false);
  }

  Future<void> _loadPage(int page, {required bool replace}) async {
    _status = replace
        ? HistoryViewStatus.loading
        : HistoryViewStatus.loadingMore;
    _errorMessage = null;
    notifyListeners();
    try {
      final from = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );
      final result = await _repository.getMyTimeline(
        from: from.toUtc(),
        to: from.add(const Duration(days: 1)).toUtc(),
        page: page,
      );
      _items = replace ? result.items : [..._items, ...result.items];
      if (replace) _attachmentsByVisit.clear();
      await _loadAttachments(_items);
      _photoHostEventIds = _selectPhotoHosts(_items);
      _page = result.page;
      _totalPages = result.totalPages;
      _status = HistoryViewStatus.loaded;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      _status = HistoryViewStatus.failed;
    } catch (_) {
      _errorMessage = 'No pudimos cargar tu historial.';
      _status = HistoryViewStatus.failed;
    }
    notifyListeners();
  }

  Future<void> _loadAttachments(List<SellerTimelineItem> items) async {
    final visitIds = items
        .where(_isVisitItem)
        .map((item) => item.resourceExternalId.trim())
        .where((externalId) => externalId.isNotEmpty)
        .toSet()
        .where((externalId) => !_attachmentsByVisit.containsKey(externalId));
    await Future.wait(
      visitIds.map((externalId) async {
        try {
          _attachmentsByVisit[externalId] = await _repository
              .getVisitAttachments(externalId);
        } catch (_) {
          // Adjuntos no disponibles no deben ocultar el resto del historial.
          _attachmentsByVisit[externalId] = const [];
        }
      }),
    );
  }
}

DateTime _day(DateTime value) => DateTime(value.year, value.month, value.day);

bool _isVisitItem(SellerTimelineItem item) {
  final value = '${item.eventType} ${item.resourceType}'.toLowerCase();
  return value.contains('visit') || value.contains('visita');
}

Set<String> _selectPhotoHosts(List<SellerTimelineItem> items) {
  final byVisit = <String, List<SellerTimelineItem>>{};
  for (final item in items.where(_isVisitItem)) {
    final visitId = item.resourceExternalId.trim();
    if (visitId.isEmpty) continue;
    byVisit.putIfAbsent(visitId, () => []).add(item);
  }
  return {
    for (final entries in byVisit.values)
      (entries.where(_isVisitCompletion).firstOrNull ?? entries.first)
          .externalId,
  };
}

bool _isVisitCompletion(SellerTimelineItem item) {
  final value = '${item.eventType} ${item.title}'.toLowerCase();
  return value.contains('checkout') ||
      value.contains('checkedout') ||
      value.contains('completed') ||
      value.contains('finaliz') ||
      value.contains('cerrad');
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
