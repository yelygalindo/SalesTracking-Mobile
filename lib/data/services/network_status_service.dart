abstract interface class NetworkStatusService {
  Future<bool> get isConnected;

  Stream<bool> get changes;
}
