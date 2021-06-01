import 'package:cacheable_request/src/adapter/abstract.dart';
import 'package:cacheable_request/src/offline_detector.dart';
import 'package:http/http.dart';

class CacheConfig {
  static SaveAdapter saveAdapter;
  static Sonar sonar;
  static Client httpClient;
}
