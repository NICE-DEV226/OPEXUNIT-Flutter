import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../auth/session_storage.dart';
import 'api_config.dart';

/// Client HTTP central pour les appels API.
/// Toutes les requêtes passent par ici (base URL, timeout, token).
/// Prêt à être branché sur le backend.
class ApiClient {
  ApiClient._();

  static final ApiClient _instance = ApiClient._();
  static ApiClient get instance => _instance;

  static String get _token => SessionStorage.getToken();

  static Uri _uri(String path, [Map<String, String>? queryParams]) {
    final pathWithSlash = path.startsWith('/') ? path : '/$path';
    final base = ApiConfig.baseUrl.replaceAll(RegExp(r'/$'), '');
    var uri = Uri.parse('$base$pathWithSlash');
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }
    return uri;
  }

  static Map<String, String> _headers({bool jsonBody = false, Map<String, String>? extra}) {
    final map = <String, String>{
      'Accept': 'application/json',
      if (jsonBody) 'Content-Type': 'application/json',
      if (_token.isNotEmpty) 'Authorization': 'Bearer $_token',
    };
    if (extra != null) map.addAll(extra);
    return map;
  }

  /// GET [path]. Query params optionnels dans [queryParams].
  static Future<http.Response> get(
    String path, {
    Map<String, String>? queryParams,
  }) async {
    return http
        .get(
          _uri(path, queryParams),
          headers: _headers(),
        )
        .timeout(ApiConfig.connectTimeout);
  }

  /// POST [path] avec [body] (Map/List → JSON, String → tel quel).
  static Future<http.Response> post(
    String path, {
    Object? body,
    Map<String, String>? queryParams,
  }) async {
    String? encoded;
    if (body != null) {
      if (body is String) {
        encoded = body;
      } else if (body is Map || body is List) {
        encoded = jsonEncode(body);
      }
    }
    return http
        .post(
          _uri(path, queryParams),
          headers: _headers(jsonBody: encoded != null),
          body: encoded,
        )
        .timeout(ApiConfig.connectTimeout);
  }

  /// PUT [path] avec [body] (Map/List → JSON).
  static Future<http.Response> put(
    String path, {
    Object? body,
    Map<String, String>? queryParams,
  }) async {
    final encoded = body != null && (body is Map || body is List) ? jsonEncode(body) : null;
    return http
        .put(
          _uri(path, queryParams),
          headers: _headers(jsonBody: encoded != null),
          body: encoded,
        )
        .timeout(ApiConfig.connectTimeout);
  }

  /// DELETE [path].
  static Future<http.Response> delete(String path, {Map<String, String>? queryParams}) async {
    return http
        .delete(
          _uri(path, queryParams),
          headers: _headers(),
        )
        .timeout(ApiConfig.connectTimeout);
  }

  /// POST [path] en multipart : fichier [file] sous le champ [fileField], plus [fields] optionnels.
  /// Utilisé pour POST /api/upload/file (target=profile, etc.).
  static Future<http.StreamedResponse> postMultipart(
    String path, {
    required File file,
    String fileField = 'file',
    Map<String, String>? fields,
  }) async {
    final uri = _uri(path);
    final request = http.MultipartRequest('POST', uri);
    request.headers['Accept'] = 'application/json';
    if (_token.isNotEmpty) request.headers['Authorization'] = 'Bearer $_token';
    request.files.add(await http.MultipartFile.fromPath(fileField, file.path));
    if (fields != null) {
      for (final e in fields.entries) {
        request.fields[e.key] = e.value;
      }
    }
    return request.send().timeout(ApiConfig.connectTimeout);
  }
}
