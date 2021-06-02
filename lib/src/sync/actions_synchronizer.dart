import 'package:cacheable_request/cacheable_request.dart';
import 'package:cacheable_request/src/action/action_response.dart';
import 'package:cacheable_request/src/action/offline_possible_action.dart';
import 'package:cacheable_request/src/action/serializable_request.dart';
import 'package:cacheable_request/src/cacheable_request_config.dart';
import 'package:cacheable_request/src/offline_detector/abstract_offline_detector.dart';

enum FailedSyncBehaviour {
  throwAndForget,
  forget,
  callback,
}

typedef FailedSyncCallback = void Function(OfflinePossibleAction action, Object e, StackTrace stackTrace);

class ActionsSynchronizer {
  late AbstractOfflineDetector _offlineDetector;

  final FailedSyncBehaviour failedSyncBehaviour;
  final FailedSyncCallback? onFail;

  ActionsSynchronizer({
    this.failedSyncBehaviour = FailedSyncBehaviour.throwAndForget,
    this.onFail,
  }) {
    this._offlineDetector = CacheableRequestConfig.offlineDetector;
  }

  Future<void> listen() async {
    await _offlineDetector.subscribeConnectionChanges(this._onConnectionChange);

    final bool isOnline = await _offlineDetector.isOnline();

    if (isOnline) {
      this._onConnectionChange(true);
    }
  }

  void _onConnectionChange(bool connected) {
    if (connected) {
      this._performActions();
    }
  }

  Future<void> _performActions() async {
    final List<SerializableRequest> savedRequests = await this._pullActions();

    for (final SerializableRequest request in savedRequests) {
      final OfflinePossibleAction action = OfflinePossibleAction.fromSerialized(request);

      try {
        final bool performed = await action.performRemotelyIfPossible();

        if (performed) {
          await CacheableRequestConfig.saveAdapter.deleteRequest(request);
        } else {
          final ActionResponse response = action.getResponse()!;
          await this._onSyncError(action, response.error, StackTrace.current);
        }
      } catch (e, stackTrace) {
        await this._onSyncError(action, e, stackTrace);
      }
    }

    if (savedRequests.isNotEmpty) {
      // TODO
    }
  }

  Future<List<SerializableRequest>> _pullActions() async {
    return CacheableRequestConfig.saveAdapter.getAll();
  }

  Future<void> _onSyncError(OfflinePossibleAction action, Object e, StackTrace stackTrace) async {
    final bool isOffline = await _offlineDetector.isOffline();

    if (isOffline) {
      return;
    }

    switch (this.failedSyncBehaviour) {
      case FailedSyncBehaviour.throwAndForget:
        await action.undo();
        await CacheableRequestConfig.saveAdapter.deleteRequest(action);
        throw e;
      case FailedSyncBehaviour.forget:
        await action.undo();
        await CacheableRequestConfig.saveAdapter.deleteRequest(action);
        break;
      case FailedSyncBehaviour.callback:
        this.onFail!(action, e, stackTrace);
        break;
    }
  }
}
