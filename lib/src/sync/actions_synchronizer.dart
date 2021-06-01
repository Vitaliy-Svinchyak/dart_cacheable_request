import 'package:cacheable_request/cacheable_request.dart';
import 'package:cacheable_request/src/action/offline_possible_action.dart';
import 'package:cacheable_request/src/action/response.dart';
import 'package:cacheable_request/src/action/serializable_request.dart';
import 'package:cacheable_request/src/offline_detector.dart';

class ActionsSynchronizer {
  static final OfflineDetector _offlineDetector = OfflineDetector();

  const ActionsSynchronizer();

  Future<void> start() async {
    await _offlineDetector.subscribeConnectionChanges(this._onConnectionChange);

    final bool isOnline = await _offlineDetector.isOnline();

    if (isOnline) {
      this._onConnectionChange(true);
    }
  }

  void _onConnectionChange(bool result) {
    if (result) {
      this._performActions();
    }
  }

  Future<void> _performActions() async {
    final List<SerializableRequest> savedRequests = await this._pullActions();

    for (int i = 0; i < savedRequests.length; i++) {
      final SerializableRequest request = savedRequests[i];
      final OfflinePossibleAction action = OfflinePossibleAction.fromSerialized(request);

      try {
        final bool success = await action.performRemotelyIfPossible();

        if (!success) {
          final ActionResponse response = action.getResponse();
          await this._onSyncError(action, response.error, StackTrace.current);
        } else {
          await CacheConfig.saveAdapter.deleteRequest(request);
        }
      } catch (e, stackTrace) {
        await this._onSyncError(action, e, stackTrace);
      }
    }

    if (savedRequests.isNotEmpty) {}
  }

  Future<List<SerializableRequest>> _pullActions() async {
    return CacheConfig.saveAdapter.getAll();
  }

  Future<void> _onSyncError(OfflinePossibleAction action, Object e, StackTrace stackTrace) async {
    final bool isOnline = await _offlineDetector.isOnline();

    if (isOnline) {
      await action.undo();
      await CacheConfig.saveAdapter.deleteRequest(action);
    }
  }
}
