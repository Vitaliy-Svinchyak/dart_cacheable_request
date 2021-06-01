import 'package:cacheable_request/src/action/abstract_action.dart';
import 'package:cacheable_request/src/action/action_response.dart';
import 'package:flutter/foundation.dart';

abstract class OnlineOnlyAction<T extends ActionResponse> extends AbstractAction<T> {
  OnlineOnlyAction();

  @protected
  Future<bool> performRemotely();

  @override
  Future<bool> perform() async {
    final bool result = await this.performRemotely();

    return result;
  }
}
