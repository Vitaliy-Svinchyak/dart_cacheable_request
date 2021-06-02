import 'dart:convert';

import 'package:cacheable_request/src/exception/connection_exception.dart';

class ActionResponse {
  String? error;

  bool get success => this.error == null;

  ActionResponse.fromJson(Map<String, dynamic> json) : this.error = json['error'];

  Map<String, dynamic> toJson() => {
        'success': this.success,
        'error': this.error.toString(),
      };

  @override
  String toString() => const JsonEncoder.withIndent('  ').convert(this);

  bool get failedBecauseOfConnection => this.error == ConnectionException.Message;
}
