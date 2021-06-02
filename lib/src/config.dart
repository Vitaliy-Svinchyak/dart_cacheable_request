import 'package:cacheable_request/cacheable_request.dart';
import 'package:cacheable_request/src/action/serializable_request.dart';
import 'package:cacheable_request/src/adapter/abstract_save_adapter.dart';
import 'package:cacheable_request/src/adapter/memory_save_adapter.dart';
import 'package:cacheable_request/src/offline_detector/abstract_offline_detector.dart';
import 'package:cacheable_request/src/offline_detector/sonar_offline_detector.dart';
import 'package:cacheable_request/src/sync/actions_synchronizer.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:logger/logger.dart';

typedef OfflineRequestBuilder = OfflinePossibleAction Function(SerializableRequest request);

class CacheableRequestConfig {
  @protected
  static late AbstractSaveAdapter saveAdapter;
  @protected
  static late Client httpClient;
  @protected
  static late AbstractOfflineDetector offlineDetector;

  static late Logger logger;

  @protected
  static final Map<String, OfflineRequestBuilder> requestBuilderRegistry = {};
  static late ActionsSynchronizer _actionsSynchronizer;

  const CacheableRequestConfig();

  CacheableRequestConfig.standard(Sonar sonar) {
    httpClient = Client();
    saveAdapter = MemorySaveAdapter();
    offlineDetector = SonarOfflineDetector(sonar);
    _actionsSynchronizer = ActionsSynchronizer();
  }

  void registerRequest(Type requestName, OfflineRequestBuilder builder) {
    requestBuilderRegistry[requestName.toString()] = builder;
  }

  void setSaveAdapter(AbstractSaveAdapter adapter) {
    saveAdapter = adapter;
  }

  void setHttpClient(Client client) {
    httpClient = client;
  }

  void setOfflineDetector(AbstractOfflineDetector detector) {
    offlineDetector = detector;
  }

  void configureActionsSynchronizer({
    FailedSyncBehaviour failedSyncBehaviour = FailedSyncBehaviour.throwAndForget,
    FailedSyncCallback? onFail,
  }) {
    _actionsSynchronizer = ActionsSynchronizer(failedSyncBehaviour: failedSyncBehaviour, onFail: onFail);
  }

  void listen({bool debug = false}) {
    assert(saveAdapter != null, 'SaveAdapter should be set');
    assert(httpClient != null, 'HttpClient should be set');
    assert(offlineDetector != null, 'OfflineDetector should be set');
    assert(_actionsSynchronizer != null, 'ActionsSynchronizer should be set');

    logger = Logger(printer: SimplePrinter(printTime: true, colors: false), level: debug ? Level.debug : Level.error);

    _actionsSynchronizer.listen();
  }
}
