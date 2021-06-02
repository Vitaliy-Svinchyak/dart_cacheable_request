import 'dart:async';

import 'package:cacheable_request/src/config.dart';
import 'package:cacheable_request/src/offline_detector/abstract_offline_detector.dart';
import 'package:connectivity/connectivity.dart';

typedef ConnectionChangeCallback = void Function(bool result);
typedef Sonar = Future<bool> Function();

class SonarOfflineDetector implements AbstractOfflineDetector {
  final Duration pingFrequency;
  final Sonar sonar;
  final int maxFailStreak;

  final List<ConnectionChangeCallback> _listeners = [];

  bool? _currentStatus;
  int _failsStreak = 0;

  SonarOfflineDetector(
    this.sonar, {
    this.pingFrequency = const Duration(seconds: 10),
    this.maxFailStreak = 2,
  }) {
    this._trackConnectionChange();
  }

  Future<bool> isOnline() {
    return this._ping();
  }

  Future<bool> isOffline() async {
    return !await this.isOnline();
  }

  void subscribeConnectionChanges(ConnectionChangeCallback callback) {
    this._listeners.add(callback);

    if (this._currentStatus != null) {
      callback(this._currentStatus!);
    }
  }

  Future<void> _trackConnectionChange() async {
    Timer.periodic(this.pingFrequency, (timer) {
      this._ping().then(this._setStatus).catchError((e) => this._setStatus(false));
    });
  }

  Future<bool> _ping() async {
    bool pingResult;
    final bool isConnectedToInternet = await this._connectedToInternet();

    if (isConnectedToInternet) {
      pingResult = await this.sonar();
    } else {
      pingResult = false;
    }

    if (pingResult) {
      this._failsStreak = 0;
    } else {
      this._failsStreak++;
    }

    return pingResult || this._failsStreak <= this.maxFailStreak;
  }

  void _setStatus(bool newStatus) {
    if (this._currentStatus == newStatus) {
      return;
    }

    this._currentStatus = newStatus;
    CacheableRequestConfig.logger.d('[${this.runtimeType}] Connection status has changed. New value: $newStatus');

    for (final ConnectionChangeCallback callback in this._listeners) {
      callback(newStatus);
    }
  }

  Future<bool> _connectedToInternet() async {
    return false;
    final ConnectivityResult connectivityResult = await Connectivity().checkConnectivity();

    return connectivityResult != ConnectivityResult.none;
  }
}
