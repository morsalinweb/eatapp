// path: lib/services/api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/app_config.dart';

/// Thin wrapper around package:http that:
///  - prefixes every path with [AppConfig.apiBaseUrl]
///  - attaches the current Supabase session's access token as a Bearer
///    header automatically (nothing to remember per-call)
///  - decodes JSON and throws [ApiException] with the backend's own error
///    message on non-2xx responses, so providers can catch one exception
///    type and show it to the user.
class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  String get _baseUrl => AppConfig.apiBaseUrl;

  Map<String, String> get _headers {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final cleanQuery = query == null
        ? null
        : query.map((k, v) => MapEntry(k, v?.toString() ?? ''))
      ?..removeWhere((k, v) => v.isEmpty);
    return Uri.parse('$_baseUrl$path').replace(queryParameters: cleanQuery);
  }

  dynamic _decode(http.Response res) {
    final body = res.body.isEmpty ? {} : jsonDecode(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final message = (body is Map && body['error'] != null)
          ? body['error'].toString()
          : 'Request failed (${res.statusCode})';
      throw ApiException(res.statusCode, message);
    }
    return body;
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    final res = await http.get(_uri(path, query), headers: _headers);
    return _decode(res);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final res = await http.post(_uri(path), headers: _headers, body: jsonEncode(body ?? {}));
    return _decode(res);
  }

  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    final res = await http.patch(_uri(path), headers: _headers, body: jsonEncode(body ?? {}));
    return _decode(res);
  }

  Future<dynamic> delete(String path) async {
    final res = await http.delete(_uri(path), headers: _headers);
    return _decode(res);
  }
}
