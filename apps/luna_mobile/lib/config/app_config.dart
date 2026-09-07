import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static const bool useMockData = false;
  static String? _cachedToken;
  static String? _customHost;

  static String? _cachedUserName;
  static String? _cachedUserEmail;

  /// Default port for backend
  static const String defaultPort = '8888';

  /// Get the active host (IP or domain).
  /// For Web and Desktop, uses localhost:8888.
  /// For Android emulator, uses 10.0.2.2:8888.
  static String get host {
    if (_customHost != null && _customHost!.isNotEmpty) {
      return _customHost!;
    }
    if (!kIsWeb && Platform.isAndroid) {
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

  /// Get cached user name
  static Future<String?> getUserName() async {
    if (_cachedUserName != null) return _cachedUserName;
    final prefs = await SharedPreferences.getInstance();
    _cachedUserName = prefs.getString('user_name');
    return _cachedUserName;
  }

  /// Get cached user email
  static Future<String?> getUserEmail() async {
    if (_cachedUserEmail != null) return _cachedUserEmail;
    final prefs = await SharedPreferences.getInstance();
    _cachedUserEmail = prefs.getString('user_email');
    return _cachedUserEmail;
  }

  /// Save user profile info
  static Future<void> setUserInfo({required String name, required String email}) async {
    _cachedUserName = name;
    _cachedUserEmail = email;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setString('user_email', email);
  }

  /// Clear token and profile info (Logout)
  static Future<void> clearToken() async {
    _cachedToken = null;
    _cachedUserName = null;
    _cachedUserEmail = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
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

