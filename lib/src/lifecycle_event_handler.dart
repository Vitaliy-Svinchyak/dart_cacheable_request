import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class LifecycleEventHandler extends WidgetsBindingObserver {
  final Map<AppLifecycleState, List<AsyncCallback>> _callbacks = {
    AppLifecycleState.resumed: [],
    AppLifecycleState.detached: [],
  };

  LifecycleEventHandler();

  void onResumed(AsyncCallback callback) {
    this._addCallback(AppLifecycleState.resumed, callback);
  }

  void onKill(AsyncCallback callback) {
    this._addCallback(AppLifecycleState.detached, callback);
  }

  void removeOnKillCallback(AsyncCallback callback) {
    this._callbacks[AppLifecycleState.detached].remove(callback);
  }

  Future<void> _notifyListeners(AppLifecycleState state) async {
    for (final AsyncCallback callback in this._callbacks[state]) {
      await callback();
    }
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
        await this._notifyListeners(AppLifecycleState.resumed);
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        await this._notifyListeners(AppLifecycleState.detached);
        break;
      case AppLifecycleState.inactive:
        // when webview opens f.e.
        break;
    }
  }

  void _addCallback(AppLifecycleState state, AsyncCallback callback) {
    if (this._callbacks[state] == null) {
      this._callbacks[state] = [];
    }

    this._callbacks[state].add(callback);
  }
}
