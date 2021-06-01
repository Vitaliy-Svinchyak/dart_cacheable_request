import 'dart:convert';

import 'package:cacheable_request/src/error_message.dart';

class ActionResponse {
  String error;
  dynamic errors;

  bool get success => this.error == null && this.errors == null;

  ActionResponse.fromJson(Map<String, dynamic> json)
      : this.error = json['error'] as String,
        this.errors = json['errors'];

  Map<String, dynamic> toJson() => {
        'error': this.error,
        'errors': this.errors,
        'success': this.success,
      };

  @override
  String toString() => const JsonEncoder.withIndent('  ').convert(this);

  bool get failedBecauseOfOffline => this.error == ErrorMessage.onlineOnly;
}
