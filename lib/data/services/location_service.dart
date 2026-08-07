import '../models/common/location_sample.dart';

enum LocationFailureType {
  servicesDisabled,
  denied,
  deniedForever,
  unavailable,
}

class LocationFailure implements Exception {
  const LocationFailure(this.type, this.message);

  final LocationFailureType type;
  final String message;

  @override
  String toString() => message;
}

abstract interface class LocationService {
  Future<LocationSample> captureCurrent();
}
