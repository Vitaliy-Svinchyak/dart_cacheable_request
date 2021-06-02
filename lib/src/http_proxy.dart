import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cacheable_request/src/action/action_response.dart';
import 'package:cacheable_request/src/config.dart';
import 'package:cacheable_request/src/exception/connection_exception.dart';
import 'package:http/http.dart' as http;

typedef ResponseBuilder<T extends ActionResponse> = T Function(Map<String, dynamic> json);
typedef OnUnauthorisedCallback = void Function();

class HttpProxy {
  const HttpProxy();

  Future<T> post<T extends ActionResponse>(
    Uri url,
    ResponseBuilder<T> responseBuilder, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return CacheableRequestConfig.httpClient
        .post(url, headers: headers, body: body, encoding: encoding)
        .then((r) => this._parseResponse<T>(r, responseBuilder))
        .catchError((dynamic e, StackTrace s) => this._onError<T>(e, s, responseBuilder));
  }

  Future<T> put<T extends ActionResponse>(
    Uri url,
    ResponseBuilder<T> responseBuilder, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return CacheableRequestConfig.httpClient
        .put(url, headers: headers, body: body, encoding: encoding)
        .then((r) => this._parseResponse<T>(r, responseBuilder))
        .catchError((dynamic e, StackTrace s) => this._onError<T>(e, s, responseBuilder));
  }

  Future<T> get<T extends ActionResponse>(
    Uri url,
    ResponseBuilder<T> responseBuilder, {
    Map<String, String>? headers,
  }) async {
    return CacheableRequestConfig.httpClient
        .get(url, headers: headers)
        .then((r) => this._parseResponse<T>(r, responseBuilder))
        .catchError((dynamic e, StackTrace s) => this._onError<T>(e, s, responseBuilder));
  }

  Future<T> _onError<T extends ActionResponse>(dynamic error, StackTrace stackTrace, ResponseBuilder<T> builder) async {
    return builder({'error': ConnectionException()});
  }

  T _parseResponse<T extends ActionResponse>(
    http.Response response,
    ResponseBuilder<T> builder,
  ) {
    if (response.statusCode == HttpStatus.ok) {
      final Map<String, dynamic> body = json.decode(response.body) as Map<String, dynamic>;
      return builder(body);
    }

    try {
      final dynamic body = json.decode(response.body);

      if (body.runtimeType == String) {
        return builder({'error': response.body});
      } else {
        return builder(body as Map<String, dynamic>);
      }
    } catch (e) {
      return builder({'error': e.toString()});
    }
  }
}
