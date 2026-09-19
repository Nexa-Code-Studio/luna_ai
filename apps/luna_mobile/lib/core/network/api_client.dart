import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

/// Custom Exception for API Errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException: $message (StatusCode: $statusCode)';
}

/// Generic HTTP Client abstraction for Remote DataSources
class ApiClient {
  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  Future<dynamic> get(String path, {Map<String, String>? queryParams}) async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}$path').replace(queryParameters: queryParams);
      final response = await _client.get(uri, headers: AppConfig.defaultHeaders);
      return _processResponse(response);
    } catch (e) {
      throw ApiException('Failed to connect to backend: $e');
    }
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}$path');
      final response = await _client.post(
        uri,
        headers: AppConfig.defaultHeaders,
        body: body != null ? jsonEncode(body) : null,
      );
      return _processResponse(response);
    } catch (e) {
      throw ApiException('Failed to send data to backend: $e');
    }
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}$path');
      final response = await _client.put(
        uri,
        headers: AppConfig.defaultHeaders,
        body: body != null ? jsonEncode(body) : null,
      );
      return _processResponse(response);
    } catch (e) {
      throw ApiException('Failed to update data on backend: $e');
    }
  }

  Future<dynamic> delete(String path) async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}$path');
      final response = await _client.delete(uri, headers: AppConfig.defaultHeaders);
      return _processResponse(response);
    } catch (e) {
      throw ApiException('Failed to delete resource on backend: $e');
    }
  }

  dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      final message = body['detail'] ?? body['message'] ?? 'HTTP Error ${response.statusCode}';
      throw ApiException(message.toString(), statusCode: response.statusCode);
    }
  }
}
