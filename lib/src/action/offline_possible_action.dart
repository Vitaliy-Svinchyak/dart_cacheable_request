import 'dart:convert';

import 'package:cacheable_request/src/action/abstract_action.dart';
import 'package:cacheable_request/src/action/action_response.dart';
import 'package:cacheable_request/src/action/serializable_request.dart';
import 'package:cacheable_request/src/cacheable_request_config.dart';
import 'package:cacheable_request/src/error/online_only_error.dart';
import 'package:cacheable_request/src/lifecycle_event_handler.dart';
import 'package:flutter/foundation.dart';

abstract class OfflinePossibleAction<T extends ActionResponse> extends AbstractAction<T> {
  static final _lifecycleEventHandler = LifecycleEventHandler();

  late int _maxRetries;
  Map<String, dynamic> metaInfo = {};

  int get currentRetries => this.metaInfo['retries'] as int;

  set currentRetries(int value) {
    this.metaInfo['retries'] = value;
  }

  OfflinePossibleAction({int maxRetries = 0}) {
    this._maxRetries = maxRetries;
    this.createdAt = DateTime.now();
  }

  @protected
  Future<void> performLocally();

  @protected
  Future<bool> performRemotely();

  Future<bool> undo();

  @protected
  String? getUniqueIdentifier() {
    return null;
  }

  @override
  Future<bool> perform() async {
    _lifecycleEventHandler.onKill(this._onKill);
    await this.performLocally();
    return this.performRemotelyIfPossible();
  }

  static OfflinePossibleAction fromSerialized(SerializableRequest request) {
    // TODO find more beautiful way
    switch (request.actionName) {
      case 'LoginAction':
//        return LoginAction.unserialize(request);
      default:
        throw ArgumentError('Unknown action: ' + request.actionName);
    }
  }

  OfflinePossibleAction.unserialize(SerializableRequest request) {
    this.id = request.id;
    this.body = request.body;
    this.metadata = request.metadata;
    this.actionName = this.runtimeType.toString();
    this._maxRetries = request.maxRetries;
    this.bodyToSend = json.decode(request.body) as Map<String, dynamic>;
    this.metaInfo = json.decode(request.metadata) as Map<String, dynamic>;
    this.createdAt = request.createdAt;
  }

  Future<bool> performRemotelyIfPossible() async {
    try {
      final bool result = await this.performRemotely();

      if (!result) {
        return this._serializeIfOfflineOrCanRetry();
      }
      _lifecycleEventHandler.removeOnKillCallback(this._onKill);

      return result;
    } catch (e) {
      return this._serializeIfOfflineOrCanRetry();
    }
  }

  Future<void> _serialize() async {
    this.actionName = this.runtimeType.toString();
    this.body = this.getBodyJson();
    this.metadata = json.encode(this.metaInfo);
    this.maxRetries = this._maxRetries;
    final String? uniqueIdentifier = this.getUniqueIdentifier();

    if (uniqueIdentifier == null) {
      await this.save();
      return;
    }

    final String actionName = this.actionName;
    final List<SerializableRequest> savedRequests =
        await CacheableRequestConfig.saveAdapter.getSavedRequestsByName(actionName);

    for (final SerializableRequest request in savedRequests) {
      final OfflinePossibleAction action = OfflinePossibleAction.fromSerialized(request);
      final bool isSameRequest = action.getUniqueIdentifier() == uniqueIdentifier;

      if (isSameRequest) {
        final bool isOlder = action.createdAt.microsecondsSinceEpoch < this.createdAt.microsecondsSinceEpoch;
        if (!isOlder) {
          action
            ..metaInfo = this.metaInfo
            ..createdAt = this.createdAt;
          await action.save();
          return;
        }

        action
          ..body = this.body
          ..createdAt = this.createdAt;
        await action.save();
        return;
      }
    }

    await this.save();
  }

  Future<bool> _serializeIfOfflineOrCanRetry() async {
    final bool messageSaysOffline = this.response?.error is OnlineOnlyError;
    final bool isOnline = !messageSaysOffline;

    final bool canRetry = this.currentRetries <= this._maxRetries;
    if (canRetry && isOnline) {
      this.currentRetries++;
    }

    final bool shouldSerialize = !isOnline || canRetry;

    if (shouldSerialize) {
      await this._serialize();
    }

    _lifecycleEventHandler.removeOnKillCallback(this._onKill);
    return shouldSerialize;
  }

  Future<void> _onKill() async {
    await this._serialize();
  }

  Future<bool> save() {
    return CacheableRequestConfig.saveAdapter.saveRequest(this);
  }
}
