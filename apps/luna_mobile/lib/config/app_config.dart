import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static const bool useMockData = false;
  static String? _cachedToken;
  static String? _customHost;

  /// Default port for backend
  static const String defaultPort = '8888';

  /// Get the active host (IP or domain).
  /// For Android emulator, uses 10.0.2.2:8888.
  /// For Windows/Desktop, uses localhost:8888.
  static String get host {
    if (_customHost != null && _customHost!.isNotEmpty) {
      return _customHost!;
    }
    if (Platform.isAndroid) {
      return '10.0.2.2:$defaultPort';
    }
    return 'localhost:$defaultPort';
  }

  static void setCustomHost(String host) {
    _customHost = host;
  }

  static String get baseUrl {
    return 'http://$host/api/v1';
  }

  static String get wsUrl {
    return 'ws://$host/api/v1';
  }

  /// Get current JWT access token
  static Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString('auth_token');
    return _cachedToken;
  }

  /// Save JWT access token
  static Future<void> setToken(String token) async {
    _cachedToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  /// Clear token (Logout)
  static Future<void> clearToken() async {
    _cachedToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  /// Default headers with Authorization if token is available
  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }
}
