import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cacheable_request/src/action/action_response.dart';
import 'package:cacheable_request/src/cacheable_request_config.dart';
import 'package:cacheable_request/src/error_message.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

typedef ResponseBuilder<T extends ActionResponse> = T Function(Map<String, dynamic> json);
typedef OnUnauthorisedCallback = void Function();

class HttpProxy {
  const HttpProxy();

  Future<T> post<T extends ActionResponse>({
    @required String url,
    @required String body,
    @required ResponseBuilder<T> builder,
    bool auth = true,
    OnUnauthorisedCallback onUnauthorised,
  }) async {
    return CacheableRequestConfig.httpClient
        .post(url, headers: await this._getHeaders(auth), body: body)
        .then((r) => this._parseResponse<T>(r, builder, onUnauthorised))
        .catchError((dynamic e, StackTrace s) => this._onError<T>(e, s, builder));
  }

  Future<T> put<T extends ActionResponse>({
    @required String url,
    @required String body,
    @required ResponseBuilder<T> builder,
    bool auth = true,
    OnUnauthorisedCallback onUnauthorised,
  }) async {
    return CacheableRequestConfig.httpClient
        .put(url, headers: await this._getHeaders(auth), body: body)
        .then((r) => this._parseResponse<T>(r, builder, onUnauthorised))
        .catchError((dynamic e, StackTrace s) => this._onError<T>(e, s, builder));
  }

  Future<T> get<T extends ActionResponse>({
    @required String url,
    @required ResponseBuilder<T> builder,
    bool auth = true,
    OnUnauthorisedCallback onUnauthorised,
  }) async {
    return CacheableRequestConfig.httpClient
        .get(url, headers: await this._getHeaders(auth))
        .then((r) => this._parseResponse<T>(r, builder, onUnauthorised))
        .catchError((dynamic e, StackTrace s) => this._onError<T>(e, s, builder));
  }

  Future<Map<String, String>> _getHeaders(bool auth) async {
    final Map<String, String> headers = {
      "Content-Type": "application/json",
      "X-Platform": Platform.isIOS ? "ios" : "android",
    };

    return headers;
  }

  Future<T> _onError<T extends ActionResponse>(dynamic error, StackTrace stackTrace, ResponseBuilder<T> builder) async {
    return builder({'error': ErrorMessage.onlineOnly});
  }

  T _parseResponse<T extends ActionResponse>(
    http.Response response,
    ResponseBuilder<T> builder,
    OnUnauthorisedCallback onUnauthorised,
  ) {
    if (response.statusCode == HttpStatus.ok) {
      final Map<String, dynamic> body = json.decode(response.body) as Map<String, dynamic>;
      return builder(body);
    }

    if (response.statusCode == HttpStatus.unauthorized) {
      if (onUnauthorised != null) {
        onUnauthorised();
      } else {
        this._onUnauthorised();
      }
    }

    try {
      final dynamic body = json.decode(response.body);

      if (body.runtimeType == String) {
        return builder({'error': response.body});
      } else {
        return builder(body as Map<String, dynamic>);
      }
    } catch (e, stacktrace) {
      return builder({'error': ErrorMessage.unknownError});
    }
  }

  void _onUnauthorised() {}
}
