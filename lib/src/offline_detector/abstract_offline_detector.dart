typedef ConnectionChangeCallback = void Function(bool result);

abstract class AbstractOfflineDetector {
  Future<bool> isOnline();

  Future<bool> isOffline();

  void subscribeConnectionChanges(ConnectionChangeCallback callback);
}
