import 'package:cacheable_request/src/action/serializable_request.dart';
import 'package:cacheable_request/src/adapter/abstract_save_adapter.dart';
import 'package:cacheable_request/src/config.dart';

class MemorySaveAdapter extends AbstractSaveAdapter {
  final List<SerializableRequest> storage = [];

  @override
  Future<bool> deleteRequest(SerializableRequest request) async {
    this.storage.removeWhere((element) => element.id == request.id);

    CacheableRequestConfig.logger.d('[MemorySaveAdapter] Deleted ${request.actionName} request with id ${request.id}');

    return true;
  }

  @override
  Future<List<SerializableRequest>> getAll() async {
    return storage;
  }

  @override
  Future<List<SerializableRequest>> getSavedRequestsByName(String name) async {
    return this.storage.where((element) => element.actionName == name).toList();
  }

  @override
  Future<bool> saveRequest(SerializableRequest request) async {
    request.id = this.storage.length;
    this.storage.add(request);

    CacheableRequestConfig.logger.d('[MemorySaveAdapter] Saved ${request.actionName} request with id ${request.id}');
    return true;
  }
}
