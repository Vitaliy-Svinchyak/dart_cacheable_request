import 'package:cacheable_request/src/config.dart';

import 'create_action.dart';

void main() async {
  CacheableRequestConfig.standard(() => Future.delayed(Duration(), () => true))
    ..registerRequest(CreateAction, (request) => CreateAction.deserialize(request))
    ..listen(debug: true);
  final action = CreateAction('her');

  await action.perform();
}
