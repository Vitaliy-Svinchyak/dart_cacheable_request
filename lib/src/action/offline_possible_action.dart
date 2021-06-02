import 'dart:convert';

import 'package:cacheable_request/src/action/abstract_action.dart';
import 'package:cacheable_request/src/action/action_response.dart';
import 'package:cacheable_request/src/action/serializable_request.dart';
import 'package:cacheable_request/src/config.dart';
import 'package:cacheable_request/src/lifecycle_event_handler.dart';
import 'package:flutter/foundation.dart';

const int int64MaxValue = 9223372036854775807;

abstract class OfflinePossibleAction<T extends ActionResponse> extends AbstractAction<T> {
  static final _lifecycleEventHandler = LifecycleEventHandler();

  late int _maxRetries;
  Map<String, dynamic> metaInfo = {};

  int get currentRetries => this.metaInfo['retries'] != null ? this.metaInfo['retries'] as int : 0;

  set currentRetries(int value) {
    this.metaInfo['retries'] = value;
  }

  OfflinePossibleAction({int maxRetries = int64MaxValue}) {
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
    CacheableRequestConfig.logger.d('[${this.runtimeType}] Performing locale action.');

    await this.performLocally();
    return this.performRemotelyIfPossible();
  }

  static OfflinePossibleAction fromSerialized(SerializableRequest request) {
    CacheableRequestConfig.logger
        .d('[OfflinePossibleAction] Deserializing ${request.actionName} request with id ${request.id}');

    // ignore: invalid_use_of_protected_member
    final builder = CacheableRequestConfig.requestBuilderRegistry[request.actionName];

    if (builder == null) {
      throw ArgumentError('Unknown action: ' + request.actionName);
    }

    return builder(request);
  }

  OfflinePossibleAction.deserialize(SerializableRequest request) {
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
    CacheableRequestConfig.logger.d('[${this.runtimeType}] Performing remote action.');

    try {
      final bool result = await this.performRemotely();

      if (!result) {
        CacheableRequestConfig.logger.d('[${this.runtimeType}] Fail.');
        return this._serializeIfOfflineOrCanRetry();
      }
      _lifecycleEventHandler.removeOnKillCallback(this._onKill);
      CacheableRequestConfig.logger.d('[${this.runtimeType}] Success.');

      return result;
    } catch (e) {
      return this._serializeIfOfflineOrCanRetry();
    }
  }

  Future<void> _serialize() async {
    CacheableRequestConfig.logger.d('[${this.runtimeType}] Serializing.');

    this.actionName = this.runtimeType.toString();
    this.body = this.getBodyJson();
    this.metadata = json.encode(this.metaInfo);
    this.maxRetries = this._maxRetries;
    final String? uniqueIdentifier = this.getUniqueIdentifier();

    if (uniqueIdentifier == null) {
      CacheableRequestConfig.logger.d('[${this.runtimeType}] Saving a new non unique request.');

      await this.save();
      return;
    }

    CacheableRequestConfig.logger.d('[${this.runtimeType}] Finding duplicates for request. ($uniqueIdentifier)');

    final String actionName = this.actionName;
    final List<SerializableRequest> savedRequests =
        await CacheableRequestConfig.saveAdapter.getSavedRequestsByName(actionName);

    for (final SerializableRequest request in savedRequests) {
      final OfflinePossibleAction action = OfflinePossibleAction.fromSerialized(request);
      final bool isSameRequest = action.getUniqueIdentifier() == uniqueIdentifier;

      if (isSameRequest) {
        CacheableRequestConfig.logger.d('[${this.runtimeType}] Duplicate found. ($uniqueIdentifier)');

        final bool currentRequestIsYounger =
            this.createdAt.microsecondsSinceEpoch > action.createdAt.microsecondsSinceEpoch;

        if (currentRequestIsYounger) {
          CacheableRequestConfig.logger.d('[${this.runtimeType}] Updating metainfo of duplicate. ($uniqueIdentifier)');
          action
            ..metaInfo = this.metaInfo
            ..createdAt = this.createdAt;
          await action.save();
          return;
        }

        CacheableRequestConfig.logger.d('[${this.runtimeType}] Updating body of duplicate. ($uniqueIdentifier)');

        action
          ..body = this.body
          ..createdAt = this.createdAt;
        await action.save();
        return;
      }
    }

    CacheableRequestConfig.logger.d('[${this.runtimeType}] Saving a new unique request. ($uniqueIdentifier)');

    await this.save();
  }

  Future<bool> _serializeIfOfflineOrCanRetry() async {
    final bool isOnline = !this.response.failedBecauseOfConnection;

    final bool canRetry = this.currentRetries <= this._maxRetries;
    if (canRetry && isOnline) {
      this.currentRetries++;
    }

    if (this.response.failedBecauseOfConnection) {
      if (canRetry) {
        String leftAttempts = this._maxRetries == int64MaxValue ? '∞' : this._maxRetries.toString();
        CacheableRequestConfig.logger.d('[${this.runtimeType}] ${this.currentRetries}/$leftAttempts attempts used.');

        await this._serialize();
      } else {
        CacheableRequestConfig.logger.d('[${this.runtimeType}] Retry attempts ended.');
      }
    } else {
      print(this.response.error);
      CacheableRequestConfig.logger.d('[${this.runtimeType}] Fail was not because of connectivity.');
    }

    _lifecycleEventHandler.removeOnKillCallback(this._onKill);

    return this.response.failedBecauseOfConnection || canRetry;
  }

  Future<void> _onKill() async {
    await this._serialize();
  }

  Future<bool> save() {
    return CacheableRequestConfig.saveAdapter.saveRequest(this);
  }
}
