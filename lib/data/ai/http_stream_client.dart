import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:opencode/core/errors/failures.dart';

final class HttpStreamClient {
  HttpStreamClient({
    http.Client? innerClient,
    this.timeout = const Duration(seconds: 45),
  }) : _inner = innerClient ?? http.Client();

  final http.Client _inner;
  final Duration timeout;

  Stream<String> postJsonLines({
    required Uri uri,
    Map<String, String>? headers,
    Object? body,
  }) async* {
    final http.Request request = http.Request('POST', uri);
    if (headers != null) {
      request.headers.addAll(headers);
    }
    if (body != null) {
      request.headers['content-type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    final http.StreamedResponse response;
    try {
      response = await _inner.send(request).timeout(timeout);
    } on TimeoutException {
      throw NetworkFailure('Request to $uri timed out');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final String errorBody = await response.stream.bytesToString();
      throw ProviderFailure('HTTP ${response.statusCode}: ${_shorten(errorBody)}');
    }

    yield* response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());
  }

  Future<Map<String, dynamic>> getJson({
    required Uri uri,
    Map<String, String>? headers,
  }) async {
    final http.Response response;
    try {
      response = await _inner.get(uri, headers: headers).timeout(timeout);
    } on TimeoutException {
      throw NetworkFailure('Request to $uri timed out');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ProviderFailure(
        'HTTP ${response.statusCode}: ${_shorten(response.body)}',
      );
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  String _shorten(String text, {int max = 300}) =>
      text.length <= max ? text : '${text.substring(0, max)}…';

  void close() => _inner.close();
}
