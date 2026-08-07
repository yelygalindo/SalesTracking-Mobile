import 'package:flutter_test/flutter_test.dart';
import 'package:urbantrack/data/models/common/location_sample.dart';
import 'package:urbantrack/data/models/workday/current_workday_response.dart';
import 'package:urbantrack/data/models/workday/workday.dart';
import 'package:urbantrack/data/repositories/workday_repository.dart';
import 'package:urbantrack/data/services/location_service.dart';
import 'package:urbantrack/ui/workday/workday_view_model.dart';

void main() {
  test(
    'starts and closes with distinct mobile timestamps, GPS and ids',
    () async {
      final repository = _RecordingWorkdayRepository();
      final locations = _QueuedLocationService([
        const LocationSample(
          latitude: -12.0464,
          longitude: -77.0428,
          accuracyMeters: 7,
        ),
        const LocationSample(
          latitude: -12.05,
          longitude: -77.04,
          accuracyMeters: 5,
        ),
      ]);
      final times = [
        DateTime.parse('2026-08-07T10:10:00-05:00'),
        DateTime.parse('2026-08-07T17:00:00-05:00'),
      ];
      final ids = ['request-start', 'request-close'];
      final viewModel = WorkdayViewModel(
        repository,
        locations,
        now: () => times.removeAt(0),
        requestId: () => ids.removeAt(0),
      );

      expect(await viewModel.startWorkday(note: 'Inicio en campo'), isTrue);
      expect(repository.startedAtUtc, DateTime.utc(2026, 8, 7, 15, 10));
      expect(repository.startLocation?.latitude, -12.0464);
      expect(repository.startRequestId, 'request-start');
      expect(viewModel.hasOpenWorkday, isTrue);

      expect(await viewModel.prepareCloseLocation(), isTrue);
      expect(viewModel.closeLocation?.accuracyMeters, 5);
      expect(await viewModel.closeWorkday(), isTrue);
      expect(repository.closedExternalId, 'workday-1');
      expect(repository.endedAtUtc, DateTime.utc(2026, 8, 7, 22));
      expect(repository.closeRequestId, 'request-close');
      expect(viewModel.hasOpenWorkday, isFalse);
    },
  );

  test('keeps the workday closed when location permission is denied', () async {
    final viewModel = WorkdayViewModel(
      _RecordingWorkdayRepository(),
      _FailingLocationService(),
    );

    expect(await viewModel.startWorkday(), isFalse);
    expect(viewModel.hasOpenWorkday, isFalse);
    expect(viewModel.errorMessage, 'Permite la ubicación para continuar.');
    expect(viewModel.status, WorkdayStatus.ready);
  });
}

class _RecordingWorkdayRepository implements WorkdayRepository {
  DateTime? startedAtUtc;
  LocationSample? startLocation;
  String? startRequestId;
  String? closedExternalId;
  DateTime? endedAtUtc;
  String? closeRequestId;

  @override
  Future<CurrentWorkdayResponse> getCurrent() async =>
      const CurrentWorkdayResponse(hasOpenWorkday: false, workday: null);

  @override
  Future<Workday> start({
    required DateTime startedAtUtc,
    required LocationSample location,
    required String clientRequestId,
    String? note,
  }) async {
    this.startedAtUtc = startedAtUtc;
    startLocation = location;
    startRequestId = clientRequestId;
    return _openWorkday();
  }

  @override
  Future<Workday> close({
    required String externalId,
    required DateTime endedAtUtc,
    required LocationSample location,
    required String clientRequestId,
  }) async {
    closedExternalId = externalId;
    this.endedAtUtc = endedAtUtc;
    closeRequestId = clientRequestId;
    return _openWorkday().copyWithEnd(endedAtUtc, location);
  }
}

class _QueuedLocationService implements LocationService {
  _QueuedLocationService(this.locations);

  final List<LocationSample> locations;

  @override
  Future<LocationSample> captureCurrent() async => locations.removeAt(0);
}

class _FailingLocationService implements LocationService {
  @override
  Future<LocationSample> captureCurrent() {
    throw const LocationFailure(
      LocationFailureType.denied,
      'Permite la ubicación para continuar.',
    );
  }
}

Workday _openWorkday() => Workday(
  externalId: 'workday-1',
  status: 'open',
  startedAtUtc: DateTime.utc(2026, 8, 7, 15, 10),
  startedReceivedAtUtc: DateTime.utc(2026, 8, 7, 15, 10, 2),
  startLatitude: -12.0464,
  startLongitude: -77.0428,
);

extension on Workday {
  Workday copyWithEnd(DateTime end, LocationSample location) => Workday(
    externalId: externalId,
    status: 'closed',
    startedAtUtc: startedAtUtc,
    startedReceivedAtUtc: startedReceivedAtUtc,
    startLatitude: startLatitude,
    startLongitude: startLongitude,
    note: note,
    endedAtUtc: end,
    endedReceivedAtUtc: end.add(const Duration(seconds: 2)),
    endLatitude: location.latitude,
    endLongitude: location.longitude,
  );
}
