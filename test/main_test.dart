import 'package:cacheable_request/src/action/serializable_request.dart';

import 'create_action.dart';

void main() {
  final savedRequest = SerializableRequest.fromJson({});
  print(CreateAction.unserialize(savedRequest));
}
