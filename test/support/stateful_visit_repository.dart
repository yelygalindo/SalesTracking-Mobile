import 'package:urbantrack/data/models/common/location_sample.dart';
import 'package:urbantrack/data/models/visit/current_visit.dart';
import 'package:urbantrack/data/models/visit/visit_target_type.dart';
import 'package:urbantrack/data/repositories/visit_repository.dart';

class StatefulVisitRepository implements VisitRepository {
  StatefulVisitRepository({this.useLocalIds = false});

  final bool useLocalIds;
  CurrentVisit? current;
  int checkInCalls = 0;
  int checkOutCalls = 0;
  DateTime? checkInAtUtc;
  DateTime? checkOutAtUtc;
  LocationSample? checkInLocation;
  LocationSample? checkOutLocation;
  String? checkInRequestId;
  String? checkOutRequestId;
  String? checkInNote;
  String? checkOutNote;
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
    checkInCalls += 1;
    this.checkInAtUtc = checkInAtUtc;
    checkInLocation = location;
    checkInRequestId = clientRequestId;
    checkInNote = note;
    current = CurrentVisit(
      type: targetType,
      externalId: useLocalIds ? 'local:$clientRequestId' : 'visit-test-id',
      targetExternalId: targetExternalId,
      targetName: targetName,
      checkInAtUtc: checkInAtUtc,
      latitude: location.latitude,
      longitude: location.longitude,
      note: note,
    );
    return current!;
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
    checkOutCalls += 1;
    this.checkOutAtUtc = checkOutAtUtc;
    checkOutLocation = location;
    checkOutRequestId = clientRequestId;
    checkOutNote = note;
    this.result = result;
    current = null;
  }

  @override
  Future<int> pendingCount() async => 0;

  @override
  Future<void> syncPending() async {}
}
