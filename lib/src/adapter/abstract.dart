import 'package:cacheable_request/src/action/serializable_request.dart';

abstract class SaveAdapter {
  Future<bool> saveRequest(SerializableRequest request);

  Future<bool> deleteRequest(SerializableRequest request);

  Future<List<SerializableRequest>> getAll();

  Future<List<SerializableRequest>> getSavedRequestsByName(String name);
}
