import 'package:cacheable_request/src/adapter/abstract.dart';
import 'package:cacheable_request/src/offline_detector/abstract_offline_detector.dart';
import 'package:cacheable_request/src/offline_detector/sonar_offline_detector.dart';
import 'package:cacheable_request/src/sync/actions_synchronizer.dart';
import 'package:http/http.dart';

class CacheableRequestConfig {
  static late SaveAdapter saveAdapter;
  static late Client httpClient;
  static late AbstractOfflineDetector offlineDetector;

  static late ActionsSynchronizer _actionsSynchronizer;

  const CacheableRequestConfig();

  CacheableRequestConfig.standard(Sonar sonar) {
    httpClient = Client();
    offlineDetector = SonarOfflineDetector(sonar);
    _actionsSynchronizer = ActionsSynchronizer();
  }

  void setSaveAdapter(SaveAdapter adapter) {
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

  void listen() {
    assert(saveAdapter != null, 'SaveAdapter should be set');
    assert(httpClient != null, 'HttpClient should be set');
    assert(offlineDetector != null, 'OfflineDetector should be set');
    assert(_actionsSynchronizer != null, 'ActionsSynchronizer should be set');

    _actionsSynchronizer.listen();
  }
}
