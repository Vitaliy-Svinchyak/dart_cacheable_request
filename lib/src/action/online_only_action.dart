import 'package:cacheable_request/src/action/action.dart';
import 'package:cacheable_request/src/action/response.dart';
import 'package:flutter/foundation.dart';

abstract class OnlineOnlyAction<T extends ActionResponse> extends Action<T> {
  OnlineOnlyAction();

  @protected
  Future<bool> performRemotely();

  @override
  Future<bool> perform() async {
    final bool result = await this.performRemotely();

    return result;
  }
}
