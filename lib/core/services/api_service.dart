/// ---------------------------------------------------------------------------
/// api_service.dart
/// ---------------------------------------------------------------------------
/// HTTP client for Google Apps Script (GAS) Web-App.
///
/// Uses the `http` package instead of Dio because Dio on Flutter Web has
/// issues with GAS redirects and response type parsing.
/// The `http` package uses the browser's native fetch API which handles
/// GAS redirects correctly.
/// ---------------------------------------------------------------------------

import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../constants/app_constants.dart';

// ─── RESULT TYPE ─────────────────────────────────────────────────────────────

class ApiResult<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  const ApiResult._({
    required this.isSuccess,
    this.data,
    this.error,
  });

  factory ApiResult.success(T data) => ApiResult._(isSuccess: true, data: data);
  factory ApiResult.failure(String error) =>
      ApiResult._(isSuccess: false, error: error);

  @override
  String toString() => isSuccess
      ? 'ApiResult.success(${data.runtimeType})'
      : 'ApiResult.failure($error)';
}

// ─── SERVICE ─────────────────────────────────────────────────────────────────

class ApiService {
  static final ApiService instance = ApiService._();

  ApiService._();

  void _log(String msg) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[ApiService] $msg');
    }
  }

  // ---------------------------------------------------------------------------
  // GET
  // ---------------------------------------------------------------------------

  Future<ApiResult<T>> get<T>({
    required String action,
    Map<String, String> queryParams = const {},
    required T Function(dynamic json) fromJson,
  }) async {
    try {
      final params = <String, String>{
        'api_key': kApiKey,
        'action': action,
        ...queryParams,
      };

      final uri = Uri.parse(kGasBaseUrl).replace(queryParameters: params);
      _log('GET $uri');

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json, text/plain, */*',
        },
      ).timeout(Duration(seconds: kApiTimeoutSeconds));

      _log('GET status: ${response.statusCode}');
      _log(
          'GET body preview: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');

      if (response.statusCode < 200 || response.statusCode >= 500) {
        return ApiResult.failure('Server error: ${response.statusCode}');
      }

      final body = _parseJson(response.body);
      if (body == null) {
        return ApiResult.failure(
            'Invalid JSON response. Body: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}');
      }

      if (body['status'] != 'success') {
        final message = body['message'] as String? ?? 'Server error';
        _log('GET server error: $message');
        return ApiResult.failure(message);
      }

      final parsed = fromJson(body['data'] ?? body);
      return ApiResult.success(parsed);
    } on Exception catch (e) {
      _log('GET Exception: $e');
      return ApiResult.failure('Network error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // POST
  // ---------------------------------------------------------------------------

  Future<ApiResult<T>> post<T>({
    required String action,
    required Map<String, dynamic> payload,
    required T Function(dynamic json) fromJson,
  }) async {
    try {
      final body = <String, dynamic>{
        'api_key': kApiKey,
        'action': action,
        ...payload,
      };

      final jsonBody = jsonEncode(body);
      _log('POST action=$action, body size=${jsonBody.length}');
      _log(
          'POST body preview: ${jsonBody.substring(0, jsonBody.length > 300 ? 300 : jsonBody.length)}');

      // Use text/plain to avoid CORS preflight — standard GAS web app trick
      final response = await http
          .post(
            Uri.parse(kGasBaseUrl),
            headers: {
              'Content-Type': 'text/plain; charset=utf-8',
            },
            body: jsonBody,
          )
          .timeout(Duration(seconds: kApiTimeoutSeconds));

      _log('POST status: ${response.statusCode}');
      _log(
          'POST response: ${response.body.substring(0, response.body.length > 300 ? 300 : response.body.length)}');

      if (response.statusCode < 200 || response.statusCode >= 500) {
        return ApiResult.failure(
            'Server error: ${response.statusCode}. Body: ${response.body}');
      }

      final responseBody = _parseJson(response.body);
      if (responseBody == null) {
        return ApiResult.failure(
            'Invalid JSON from server. Body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
      }

      if (responseBody['status'] != 'success') {
        final message = responseBody['message'] as String? ?? 'Server error';
        _log('POST server error: $message');
        return ApiResult.failure(message);
      }

      final parsed = fromJson(responseBody);
      return ApiResult.success(parsed);
    } on Exception catch (e) {
      _log('POST Exception: $e');
      return ApiResult.failure('Network error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Map<String, dynamic>? _parseJson(String raw) {
    if (raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      _log('JSON decoded but not a Map: ${decoded.runtimeType}');
      return null;
    } catch (e) {
      _log('JSON parse error: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Domain methods
  // ---------------------------------------------------------------------------

  Future<bool> ping() async {
    final result = await get<bool>(
      action: 'ping',
      fromJson: (_) => true,
    );
    return result.isSuccess;
  }

  Future<ApiResult<Map<String, dynamic>>> pull(String lastSyncedAt) async {
    return get<Map<String, dynamic>>(
      action: 'pull',
      queryParams: {
        if (lastSyncedAt.isNotEmpty) 'last_synced_at': lastSyncedAt,
      },
      fromJson: (json) {
        if (json is Map<String, dynamic>) return json;
        if (json is Map) return Map<String, dynamic>.from(json);
        return {};
      },
    );
  }

  Future<ApiResult<Map<String, dynamic>>> push(
      List<Map<String, dynamic>> changes) async {
    return post<Map<String, dynamic>>(
      action: 'push',
      payload: {'changes': changes},
      fromJson: (json) {
        if (json is Map<String, dynamic>) return json;
        if (json is Map) return Map<String, dynamic>.from(json);
        return {};
      },
    );
  }
}

// ─── RIVERPOD PROVIDER ───────────────────────────────────────────────────────

final apiServiceProvider = Provider<ApiService>(
  (_) => ApiService.instance,
  name: 'apiServiceProvider',
);
