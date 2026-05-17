import 'dart:convert';
import 'dart:io' as io;

import '../errors.dart';

/// Thin wrapper around `dart:io.HttpClient` that POSTs JSON bodies and decodes
/// JSON responses for the Moamalat PayLink endpoints. Renamed from `HttpClient`
/// in the prototype so it doesn't collide with `dart:io.HttpClient` when
/// imported alongside it.
class MoamalatHttpClient {
  final Duration timeout;
  final io.HttpClient _client;

  MoamalatHttpClient({
    this.timeout = const Duration(seconds: 10),
    io.HttpClient? client,
  }) : _client = client ?? io.HttpClient();

  Future<Map<String, dynamic>> postJson(
    Uri uri,
    Map<String, dynamic> body,
  ) async {
    final request = await _openPost(uri);
    final payload = utf8.encode(jsonEncode(body));
    request.headers.set(io.HttpHeaders.contentTypeHeader, 'application/json');
    request.headers.set(io.HttpHeaders.acceptLanguageHeader, 'en');
    request.contentLength = payload.length;
    request.add(payload);
    final response = await _close(request);
    final responseBody = await utf8.decoder.bind(response).join();
    if (response.statusCode < 200 || response.statusCode > 299) {
      throw MoamalatPaymentError(
        responseBody.isEmpty ? response.reasonPhrase : responseBody,
        statusCode: response.statusCode,
      );
    }
    final decoded = _decodeJson(responseBody);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    throw const MoamalatPaymentError(
      'Expected JSON object in PayByCard response',
    );
  }

  Future<io.HttpClientRequest> _openPost(Uri uri) async {
    try {
      return await _client.postUrl(uri).timeout(timeout);
    } on Object catch (error) {
      throw MoamalatPaymentError(
        'Unable to open PayByCard request',
        cause: error,
      );
    }
  }

  Future<io.HttpClientResponse> _close(io.HttpClientRequest request) async {
    try {
      return await request.close().timeout(timeout);
    } on Object catch (error) {
      throw MoamalatPaymentError(
        'Unable to complete PayByCard request',
        cause: error,
      );
    }
  }

  Object? _decodeJson(String responseBody) {
    try {
      return jsonDecode(responseBody);
    } on Object catch (error) {
      throw MoamalatPaymentError(
        'Error decoding PayByCard response',
        cause: error,
      );
    }
  }

  void close({bool force = false}) => _client.close(force: force);
}
