import 'dart:io';

class AppConfig {
  static const bool useMockData = false;

  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://localhost:8888/api/v1';
    }
    return 'http://localhost:8888/api/v1';
  }

  static String get wsUrl {
    return 'ws://localhost:8888/api/v1';
  }
}
