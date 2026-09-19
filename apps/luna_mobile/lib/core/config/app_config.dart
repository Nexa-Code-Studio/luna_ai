import 'package:flutter/foundation.dart';

/// AppConfig holds global application environment settings.
/// 
/// Default behavior: `flutter run` connects directly to production domain `luna.nexacode.dev`.
/// Local mode: Pass `--dart-define=USE_LOCAL_API=true` or `--dart-define=LOCAL=true` or set `AppConfig.useLocalApi = true`.
class AppConfig {
  /// Toggle to switch between Static Mock Data and Dynamic Backend API Data
  static bool useMockData = false;

  /// Environment compile-time flag: --dart-define=USE_LOCAL_API=true or --dart-define=LOCAL=true
  /// Defaults to `false` (Production: luna.nexacode.dev).
  static bool useLocalApi = const bool.fromEnvironment(
    'USE_LOCAL_API',
    defaultValue: bool.fromEnvironment('LOCAL', defaultValue: false),
  );

  /// Production & Local Base URLs
  static const String _prodBaseUrl = 'https://luna.nexacode.dev/api/v1';
  static const String _prodWsUrl = 'wss://luna.nexacode.dev';

  static const String _localBaseUrl = 'http://localhost:8888/api/v1';
  static const String _localWsUrl = 'ws://localhost:8888';

  /// Base API URL for backend integration.
  /// Defaults to production domain `https://luna.nexacode.dev/api/v1` when running `flutter run`.
  /// Switches to `http://localhost:8888/api/v1` (or 10.0.2.2 on Android) when `useLocalApi` is true.
  static String get baseUrl {
    if (!useLocalApi) return _prodBaseUrl;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8888/api/v1';
    }
    return _localBaseUrl;
  }

  /// WebSocket URL for real-time counseling/audio streaming.
  /// Defaults to production domain `wss://luna.nexacode.dev` when running `flutter run`.
  /// Switches to `ws://localhost:8888` (or 10.0.2.2 on Android) when `useLocalApi` is true.
  static String get wsUrl {
    if (!useLocalApi) return _prodWsUrl;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'ws://10.0.2.2:8888';
    }
    return _localWsUrl;
  }

  /// Optional auth token storage in memory
  static String? authToken;

  /// Utility headers for HTTP requests
  static Map<String, String> get defaultHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };
}
