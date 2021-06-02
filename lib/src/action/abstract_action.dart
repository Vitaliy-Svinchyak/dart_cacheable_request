import 'dart:convert';

import 'package:cacheable_request/src/action/action_response.dart';
import 'package:cacheable_request/src/action/serializable_request.dart';
import 'package:cacheable_request/src/http_proxy.dart';
import 'package:flutter/foundation.dart';

abstract class AbstractAction<T extends ActionResponse> extends SerializableRequest {
  Map<String, dynamic> bodyToSend = {};

  @protected
  late T response;

  HttpProxy httpProxy = HttpProxy();

  AbstractAction();

  Future<bool> perform();

  T? getResponse() {
    return this.response;
  }

  @override
  String toString() => const JsonEncoder.withIndent('  ').convert(this);

  @protected
  String getBodyJson() {
    return json.encode(this.bodyToSend);
  }
}
