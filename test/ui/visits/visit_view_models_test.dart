import 'package:flutter_test/flutter_test.dart';
import 'package:urbantrack/data/models/common/location_sample.dart';
import 'package:urbantrack/data/models/visit/current_visit.dart';
import 'package:urbantrack/data/models/visit/visit_target_type.dart';
import 'package:urbantrack/data/repositories/visit_repository.dart';
import 'package:urbantrack/data/services/location_service.dart';
import 'package:urbantrack/ui/visits/visit_check_in_view_model.dart';
import 'package:urbantrack/ui/visits/visit_check_out_view_model.dart';

void main() {
  test('captures mobile time and GPS for check-in', () async {
    final visits = _RecordingVisitRepository();
    final viewModel = VisitCheckInViewModel(
      visits,
      _FixedLocationService(),
      targetType: VisitTargetType.customer,
      targetExternalId: 'customer-id',
      targetName: 'Cliente Norte',
      requestId: () => 'check-in-request',
      now: () => DateTime.utc(2026, 8, 7, 16),
    );
    await viewModel.initialize();

    expect(await viewModel.checkIn('Presentar propuesta'), isTrue);
    expect(visits.checkInAtUtc, DateTime.utc(2026, 8, 7, 16));
    expect(visits.checkInRequestId, 'check-in-request');
    expect(visits.checkInLocation?.latitude, -17.75);
  });

  test('records result and mobile time for check-out', () async {
    final visits = _RecordingVisitRepository(current: _visit);
    final viewModel = VisitCheckOutViewModel(
      visits,
      _FixedLocationService(),
      requestId: () => 'check-out-request',
      now: () => DateTime.utc(2026, 8, 7, 17),
    );
    await viewModel.initialize();

    expect(
      await viewModel.checkOut(
        result: 'Gestión realizada',
        note: 'Avance validado',
      ),
      isTrue,
    );
    expect(visits.checkOutAtUtc, DateTime.utc(2026, 8, 7, 17));
    expect(visits.checkOutRequestId, 'check-out-request');
    expect(visits.result, 'Gestión realizada');
  });
}

class _RecordingVisitRepository implements VisitRepository {
  _RecordingVisitRepository({this.current});

  CurrentVisit? current;
  DateTime? checkInAtUtc;
  LocationSample? checkInLocation;
  String? checkInRequestId;
  DateTime? checkOutAtUtc;
  String? checkOutRequestId;
  String? result;

  @override
  Future<CurrentVisit?> getCurrent() async => current;

  @override
  Future<CurrentVisit> checkIn({
    required VisitTargetType targetType,
    required String targetExternalId,
    required String targetName,
    required DateTime checkInAtUtc,
    required LocationSample location,
    required String clientRequestId,
    String? note,
  }) async {
    this.checkInAtUtc = checkInAtUtc;
    checkInLocation = location;
    checkInRequestId = clientRequestId;
    return CurrentVisit(
      type: targetType,
      externalId: 'visit-id',
      targetExternalId: targetExternalId,
      targetName: targetName,
      checkInAtUtc: checkInAtUtc,
      latitude: location.latitude,
      longitude: location.longitude,
      note: note,
    );
  }

  @override
  Future<void> checkOut({
    required CurrentVisit visit,
    required DateTime checkOutAtUtc,
    required LocationSample location,
    required String clientRequestId,
    String? note,
    String? result,
  }) async {
    this.checkOutAtUtc = checkOutAtUtc;
    checkOutRequestId = clientRequestId;
    this.result = result;
    current = null;
  }

  @override
  Future<int> pendingCount() async => 0;

  @override
  Future<void> syncPending() async {}
}

class _FixedLocationService implements LocationService {
  @override
  Future<LocationSample> captureCurrent() async => _location;
}

const _location = LocationSample(
  latitude: -17.75,
  longitude: -63.18,
  accuracyMeters: 6,
);

final _visit = CurrentVisit(
  type: VisitTargetType.project,
  externalId: 'visit-id',
  targetExternalId: 'project-id',
  targetName: 'Obra Norte',
  checkInAtUtc: DateTime.utc(2026, 8, 7, 16),
  latitude: -17.75,
  longitude: -63.18,
  note: null,
);
