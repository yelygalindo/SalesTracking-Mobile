import '../models/auth/auth_session.dart';
import '../models/attachment/project_attachment.dart';
import '../models/history/project_visit.dart';
import '../models/history/seller_timeline_item.dart';
import '../models/history/seller_timeline_page.dart';
import '../services/api_exception.dart';
import '../services/history_service.dart';
import 'auth_repository.dart';
import 'history_repository.dart';

class RemoteHistoryRepository implements HistoryRepository {
  const RemoteHistoryRepository(this._service, this._authRepository);

  final HistoryService _service;
  final AuthRepository _authRepository;

  @override
  Future<SellerTimelinePage> getMyTimeline({
    DateTime? from,
    DateTime? to,
    int page = 1,
    int pageSize = 30,
  }) async {
    final session = await _session();
    final sellerExternalId = session.user.externalId?.trim();
    if (sellerExternalId == null || sellerExternalId.isEmpty) {
      throw const ApiException(
        message: 'Tu usuario no tiene un identificador de vendedor.',
      );
    }
    final visitsFuture = _service
        .getVisits(
          session.accessToken,
          sellerExternalId: sellerExternalId,
          from: from,
          to: to,
        )
        .catchError((_) => <ProjectVisit>[]);
    try {
      final firstPage = await _service.getSellerTimeline(
        session.accessToken,
        sellerExternalId,
        from: from,
        to: to,
        page: 1,
        pageSize: 100,
      );
      final timelineItems = <SellerTimelineItem>[...firstPage.items];
      for (var nextPage = 2; nextPage <= firstPage.totalPages; nextPage++) {
        final result = await _service.getSellerTimeline(
          session.accessToken,
          sellerExternalId,
          from: from,
          to: to,
          page: nextPage,
          pageSize: 100,
        );
        timelineItems.addAll(result.items);
      }
      final visits = await visitsFuture;
      return _mergeAndPaginateTimeline(
        timelineItems,
        visits,
        page: page,
        pageSize: pageSize,
      );
    } on ApiException catch (error) {
      if (error.statusCode != 403) rethrow;
      final visits = await visitsFuture;
      return _timelineFromVisits(visits, page: page, pageSize: pageSize);
    }
  }

  @override
  Future<List<SellerTimelineItem>> getCustomerTimeline(
    String customerExternalId,
  ) async {
    final session = await _session();
    return _service.getCustomerTimeline(
      session.accessToken,
      customerExternalId,
    );
  }

  @override
  Future<List<ProjectVisit>> getCustomerVisits(
    String customerExternalId,
  ) async {
    final session = await _session();
    return _service.getCustomerVisits(session.accessToken, customerExternalId);
  }

  @override
  Future<List<ProjectVisit>> getProjectVisits(
    String projectExternalId, {
    String? sellerExternalId,
    DateTime? from,
    DateTime? to,
  }) async {
    final session = await _session();
    return _service.getProjectVisits(
      session.accessToken,
      projectExternalId,
      sellerExternalId: sellerExternalId,
      from: from,
      to: to,
    );
  }

  @override
  Future<List<ProjectAttachment>> getVisitAttachments(
    String visitExternalId,
  ) async {
    final session = await _session();
    return _service.getVisitAttachments(session.accessToken, visitExternalId);
  }

  Future<AuthSession> _session() async {
    final session = await _authRepository.restoreSession();
    if (session == null) {
      throw const ApiException(
        statusCode: 401,
        message: 'Tu sesión expiró. Inicia sesión nuevamente.',
      );
    }
    return session;
  }
}

SellerTimelinePage _timelineFromVisits(
  List<ProjectVisit> visits, {
  required int page,
  required int pageSize,
}) {
  final items = <SellerTimelineItem>[];
  for (final visit in visits) {
    final targetName = _visitTargetName(visit);
    items.add(
      SellerTimelineItem(
        externalId: '${visit.externalId}-checkin',
        eventType: 'ProjectVisitCheckedIn',
        resourceType: 'ProjectVisit',
        resourceExternalId: visit.externalId,
        title: 'Visita iniciada · $targetName',
        description: _checkInDescription(visit),
        occurredAtUtc: visit.visitedAtUtc,
      ),
    );
    if (visit.checkOutAtUtc case final checkOutAt?) {
      items.add(
        SellerTimelineItem(
          externalId: '${visit.externalId}-checkout',
          eventType: 'ProjectVisitCheckedOut',
          resourceType: 'ProjectVisit',
          resourceExternalId: visit.externalId,
          title: 'Visita finalizada · $targetName',
          description: _checkOutDescription(visit),
          occurredAtUtc: checkOutAt,
        ),
      );
    }
  }
  items.sort((a, b) => b.occurredAtUtc.compareTo(a.occurredAtUtc));
  final safePage = page < 1 ? 1 : page;
  final safePageSize = pageSize < 1 ? 30 : pageSize;
  final start = (safePage - 1) * safePageSize;
  final pageItems = start >= items.length
      ? const <SellerTimelineItem>[]
      : items.sublist(start, (start + safePageSize).clamp(0, items.length));
  final totalPages = items.isEmpty
      ? 0
      : ((items.length + safePageSize - 1) ~/ safePageSize);
  return SellerTimelinePage(
    items: pageItems,
    page: safePage,
    pageSize: safePageSize,
    totalItems: items.length,
    totalPages: totalPages,
  );
}

SellerTimelinePage _mergeAndPaginateTimeline(
  List<SellerTimelineItem> timeline,
  List<ProjectVisit> visits, {
  required int page,
  required int pageSize,
}) {
  final items = <SellerTimelineItem>[
    for (final item in timeline)
      if (!_isRedundantVisitRegistration(item, timeline)) item,
  ];
  final existingVisitIds = items
      .where((item) => item.eventType.toLowerCase().contains('checkout'))
      .map((item) => item.resourceExternalId.trim())
      .toSet();
  for (final visit in visits) {
    final checkOutAt = visit.checkOutAtUtc;
    if (checkOutAt == null || existingVisitIds.contains(visit.externalId)) {
      continue;
    }
    final targetName = _visitTargetName(visit);
    items.add(
      SellerTimelineItem(
        externalId: '${visit.externalId}-checkout',
        eventType: 'ProjectVisitCheckedOut',
        resourceType: 'ProjectVisit',
        resourceExternalId: visit.externalId,
        title: 'Visita finalizada · $targetName',
        description: _checkOutDescription(visit),
        occurredAtUtc: checkOutAt,
      ),
    );
  }
  items.sort((a, b) => b.occurredAtUtc.compareTo(a.occurredAtUtc));
  return _paginateTimeline(items, page: page, pageSize: pageSize);
}

bool _isRedundantVisitRegistration(
  SellerTimelineItem candidate,
  List<SellerTimelineItem> timeline,
) {
  if (candidate.eventType.trim().toLowerCase() != 'visitregistered') {
    return false;
  }
  return timeline.any((item) {
    if (item.eventType.trim().toLowerCase() != 'visit') return false;
    if (item.resourceExternalId.trim() != candidate.resourceExternalId.trim()) {
      return false;
    }
    return item.occurredAtUtc.difference(candidate.occurredAtUtc).abs() <
        const Duration(minutes: 2);
  });
}

SellerTimelinePage _paginateTimeline(
  List<SellerTimelineItem> items, {
  required int page,
  required int pageSize,
}) {
  final safePage = page < 1 ? 1 : page;
  final safePageSize = pageSize < 1 ? 30 : pageSize;
  final start = (safePage - 1) * safePageSize;
  final pageItems = start >= items.length
      ? const <SellerTimelineItem>[]
      : items.sublist(start, (start + safePageSize).clamp(0, items.length));
  final totalPages = items.isEmpty
      ? 0
      : ((items.length + safePageSize - 1) ~/ safePageSize);
  return SellerTimelinePage(
    items: pageItems,
    page: safePage,
    pageSize: safePageSize,
    totalItems: items.length,
    totalPages: totalPages,
  );
}

String _checkInDescription(ProjectVisit visit) {
  final parts = <String>[
    'Ubicación ${visit.latitude.toStringAsFixed(5)}, '
        '${visit.longitude.toStringAsFixed(5)}',
    if (visit.notes?.trim().isNotEmpty == true) visit.notes!.trim(),
  ];
  return parts.join(' · ');
}

String _checkOutDescription(ProjectVisit visit) {
  final parts = <String>[
    if (visit.result?.trim().isNotEmpty == true)
      'Resultado: ${visit.result!.trim()}',
    if (visit.checkOutNote?.trim().isNotEmpty == true)
      visit.checkOutNote!.trim(),
  ];
  return parts.isEmpty ? 'Visita cerrada.' : parts.join(' · ');
}

String _visitTargetName(ProjectVisit visit) {
  if (visit.projectName.trim().isNotEmpty) return visit.projectName.trim();
  if (visit.customerName.trim().isNotEmpty) return visit.customerName.trim();
  return 'Visita';
}
