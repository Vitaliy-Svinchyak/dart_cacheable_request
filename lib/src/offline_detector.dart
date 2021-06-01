import 'dart:async';

import 'package:cacheable_request/src/cache_config.dart';
import 'package:connectivity/connectivity.dart';

typedef ConnectionChangeCallback = void Function(bool result);
typedef Sonar = Future<bool> Function();

class OfflineDetector {
  static const Duration _pingFrequency = Duration(seconds: 2);

  final List<Function> _listeners = [];

  bool _currentStatus;
  int failsStreak = 0;

  OfflineDetector() {
    this._trackConnectionChange();
  }

  Future<bool> isOnline() {
    return this._ping();
  }

  Future<bool> isOffline() async {
    return !await isOnline();
  }

  Future<void> subscribeConnectionChanges(ConnectionChangeCallback callback) async {
    this._listeners.add(callback);

    if (this._currentStatus != null) {
      callback(this._currentStatus);
    }
  }

  Future<void> _trackConnectionChange() async {
    Timer.periodic(_pingFrequency, (timer) {
      this._ping().then((newStatus) => this._setStatus(newStatus)).catchError((e) => this._setStatus(false));
    });
  }

  Future<bool> _ping() async {
    bool result;
    final bool isConnectedToInternet = await this._connectedToInternet();

    if (isConnectedToInternet) {
      result = await CacheConfig.sonar();
    } else {
      result = isConnectedToInternet;
    }

    if (result) {
      this.failsStreak = 0;
    } else {
      this.failsStreak++;
    }

    return result || this.failsStreak <= 2;
  }

  void _setStatus(bool newStatus) {
    if (this._currentStatus != newStatus) {
      for (final Function callback in this._listeners) {
        callback(newStatus);
      }
    }

    this._currentStatus = newStatus;
  }

  Future<bool> _connectedToInternet() async {
    final ConnectivityResult connectivityResult = await Connectivity().checkConnectivity();

    return connectivityResult != ConnectivityResult.none;
  }
}
