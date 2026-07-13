import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_exception.dart';
import 'app_config.dart';
import 'token_storage.dart';

/// Thin wrapper around [http.Client] for talking to the ProInterview backend.
///
/// Unwraps the backend's `{success, ...}` response envelope and throws
/// [ApiException] on failure. Attaches the stored bearer token to
/// authenticated calls and makes a single best-effort attempt to refresh it
/// on a 401 before giving up - this is an intentional simplification (no
/// request queueing for concurrent 401s), acceptable for a small app.
class ApiClient {
  final http.Client _httpClient;
  final TokenStorage _tokenStorage;

  ApiClient({http.Client? httpClient, TokenStorage? tokenStorage})
      : _httpClient = httpClient ?? http.Client(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  Future<dynamic> get(String path, {Map<String, String>? query, bool auth = true}) {
    return _send('GET', path, query: query, auth: auth);
  }

  Future<dynamic> post(String path, {Object? body, bool auth = true}) {
    return _send('POST', path, body: body, auth: auth);
  }

  Future<dynamic> patch(String path, {Object? body, bool auth = true}) {
    return _send('PATCH', path, body: body, auth: auth);
  }

  Future<dynamic> delete(String path, {Object? body, bool auth = true}) {
    return _send('DELETE', path, body: body, auth: auth);
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = Uri.parse(AppConfig.apiBaseUrl);
    return base.replace(
      path: '${base.path}$path',
      queryParameters: query != null && query.isNotEmpty ? query : null,
    );
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
    required bool auth,
    bool isRetry = false,
  }) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await _tokenStorage.accessToken;
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }

    final uri = _uri(path, query);
    late http.Response response;
    try {
      final request = http.Request(method, uri)
        ..headers.addAll(headers)
        ..body = body != null ? jsonEncode(body) : '';
      final streamed = await _httpClient.send(request).timeout(AppConfig.requestTimeout);
      response = await http.Response.fromStream(streamed);
    } catch (e) {
      throw ApiException('Không thể kết nối tới máy chủ: $e');
    }

    Map<String, dynamic>? decoded;
    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        // non-JSON body, fall through to status-code handling below
      }
    }

    if (response.statusCode == 401 && auth && !isRetry) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        return _send(method, path, body: body, query: query, auth: auth, isRetry: true);
      }
      await _tokenStorage.clear();
      throw ApiException(
        decoded?['error'] as String? ?? decoded?['message'] as String? ?? 'Phiên đăng nhập đã hết hạn.',
        statusCode: 401,
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300 || decoded?['success'] == false) {
      final message = decoded?['error'] as String? ??
          decoded?['message'] as String? ??
          'Yêu cầu thất bại (mã ${response.statusCode}).';
      throw ApiException(message, statusCode: response.statusCode);
    }

    return decoded;
  }

  Future<bool> _tryRefreshToken() async {
    final refreshToken = await _tokenStorage.refreshToken;
    if (refreshToken == null) return false;
    try {
      final result = await _send(
        'POST',
        '/auth/refresh',
        body: {'refreshToken': refreshToken},
        auth: false,
      ) as Map<String, dynamic>;
      final newToken = result['token'] as String?;
      final newRefreshToken = result['refreshToken'] as String?;
      if (newToken == null || newRefreshToken == null) return false;
      await _tokenStorage.saveTokens(accessToken: newToken, refreshToken: newRefreshToken);
      return true;
    } catch (_) {
      return false;
    }
  }
}
