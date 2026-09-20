import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static bool useMockData = false;
  static String? authToken;
  static String? _cachedRefreshToken;
  static String? _customHost;

  static String? _cachedUserName;
  static String? _cachedUserEmail;

  /// Compile-time environment flag: --dart-define=USE_LOCAL_API=true or --dart-define=LOCAL=true
  static const bool useLocalApi = bool.fromEnvironment(
    'USE_LOCAL_API',
    defaultValue: bool.fromEnvironment('LOCAL', defaultValue: false),
  );

  /// Compile-time emulator flag: --dart-define=IS_EMULATOR=true or --dart-define=USE_EMULATOR=true
  /// When true, Android Emulator uses 10.0.2.2:8888 instead of 127.0.0.1:8888.
  static const bool isEmulator = bool.fromEnvironment(
    'IS_EMULATOR',
    defaultValue: bool.fromEnvironment(
      'USE_EMULATOR',
      defaultValue: bool.fromEnvironment('EMULATOR', defaultValue: false),
    ),
  );

  /// Optional compile-time custom host: --dart-define=LOCAL_HOST=192.168.1.100:8888
  static const String customLocalHost = String.fromEnvironment(
    'LOCAL_HOST',
    defaultValue: String.fromEnvironment('HOST', defaultValue: ''),
  );

  /// Production server domain
  static const String defaultServerHost = 'luna.nexacode.dev';

  /// Local development host (127.0.0.1:8888 with adb reverse for USB device, web, desktop)
  static const String localServerHost = '127.0.0.1:8888';

  /// Android emulator host (10.0.2.2:8888)
  static const String emulatorServerHost = '10.0.2.2:8888';

  /// Get the active host (IP or domain).
  /// Respects --dart-define=USE_LOCAL_API=true when running locally.
  static String get host {
    if (_customHost != null && _customHost!.isNotEmpty) {
      return _customHost!;
    }
    if (customLocalHost.isNotEmpty) {
      return customLocalHost;
    }
    if (useLocalApi) {
      if (isEmulator) {
        return emulatorServerHost;
      }
      return localServerHost;
    }
    return defaultServerHost;
  }

  static void setCustomHost(String host) {
    _customHost = host;
  }

  /// Whether the current connection requires secure protocol (HTTPS / WSS).
  /// Production domain uses HTTPS/WSS, while local dev loopbacks use HTTP/WS.
  static bool get isSecure {
    if (useLocalApi) return false;
    final currentHost = host;
    if (currentHost.startsWith('127.') ||
        currentHost.startsWith('10.') ||
        currentHost.startsWith('192.168.') ||
        currentHost.startsWith('localhost')) {
      return false;
    }
    return true;
  }

  static String get httpScheme => isSecure ? 'https' : 'http';
  static String get wsScheme => isSecure ? 'wss' : 'ws';

  static String get baseUrl {
    if (host.startsWith('http://') || host.startsWith('https://')) {
      return '$host/api/v1';
    }
    return '$httpScheme://$host/api/v1';
  }

  static String get wsUrl {
    if (host.startsWith('ws://') || host.startsWith('wss://')) {
      return '$host/api/v1';
    }
    return '$wsScheme://$host/api/v1';
  }

  /// Get current JWT access token
  static Future<String?> getToken() async {
    if (authToken != null) return authToken;
    final prefs = await SharedPreferences.getInstance();
    authToken = prefs.getString('auth_token');
    return authToken;
  }

  /// Save JWT access token
  static Future<void> setToken(String token) async {
    authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  /// Get current JWT refresh token
  static Future<String?> getRefreshToken() async {
    if (_cachedRefreshToken != null) return _cachedRefreshToken;
    final prefs = await SharedPreferences.getInstance();
    _cachedRefreshToken = prefs.getString('refresh_token');
    return _cachedRefreshToken;
  }

  /// Save JWT refresh token
  static Future<void> setRefreshToken(String refreshToken) async {
    _cachedRefreshToken = refreshToken;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('refresh_token', refreshToken);
  }

  /// Save both Access and Refresh tokens
  static Future<void> setTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    authToken = accessToken;
    _cachedRefreshToken = refreshToken;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
  }

  /// Refresh access token using stored refresh token
  static Future<bool> refreshAccessToken() async {
    try {
      final rfToken = await getRefreshToken();
      if (rfToken == null || rfToken.isEmpty) return false;

      final res = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'refresh_token': rfToken,
        }),
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final newAccess = data['access_token']?.toString();
        final newRefresh = data['refresh_token']?.toString() ?? rfToken;

        if (newAccess != null && newAccess.isNotEmpty) {
          await setTokens(accessToken: newAccess, refreshToken: newRefresh);
          if (data['user'] is Map<String, dynamic>) {
            final userMap = data['user'] as Map<String, dynamic>;
            await setUserInfo(
              name: userMap['name']?.toString() ?? _cachedUserName ?? 'Sahabat LUNA',
              email: userMap['email']?.toString() ?? _cachedUserEmail ?? '',
            );
          }
          return true;
        }
      }
    } catch (_) {}
    return false;
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
    authToken = null;
    _cachedRefreshToken = null;
    _cachedUserName = null;
    _cachedUserEmail = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
  }

  /// Synchronous default headers
  static Map<String, String> get defaultHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (authToken != null && authToken!.isNotEmpty)
          'Authorization': 'Bearer $authToken',
      };

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

