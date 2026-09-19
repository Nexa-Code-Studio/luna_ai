import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/config/app_config.dart';

class VoiceCallRepository {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  final StreamController<Map<String, dynamic>> _eventController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Uint8List> _audioStreamController =
      StreamController<Uint8List>.broadcast();

  Stream<Map<String, dynamic>> get eventStream => _eventController.stream;
  Stream<Uint8List> get audioStream => _audioStreamController.stream;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  Future<Map<String, dynamic>> fetchTodayVoiceSessions({int page = 1, int limit = 10}) async {
    try {
      final String rawBase = AppConfig.baseUrl.endsWith('/')
          ? AppConfig.baseUrl.substring(0, AppConfig.baseUrl.length - 1)
          : AppConfig.baseUrl;
      final String endpointPath = rawBase.endsWith('/api/v1')
          ? '/conversations/today'
          : '/api/v1/conversations/today';
      final uri = Uri.parse('$rawBase$endpointPath?page=$page&limit=$limit');

      debugPrint('📡 [CALL REPO] GET Today Conversations Paginated: $uri');

      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final List<dynamic> rawItems = decoded['items'] as List<dynamic>? ?? [];
          final items = rawItems.map((item) => Map<String, dynamic>.from(item as Map)).toList();
          return {
            'items': items,
            'total': decoded['total'] ?? items.length,
            'page': decoded['page'] ?? page,
            'has_more': decoded['has_more'] ?? false,
          };
        } else if (decoded is List) {
          final items = decoded.map((item) => Map<String, dynamic>.from(item as Map)).toList();
          return {
            'items': items,
            'total': items.length,
            'page': page,
            'has_more': false,
          };
        }
      }
      return {'items': <Map<String, dynamic>>[], 'total': 0, 'page': page, 'has_more': false};
    } catch (e) {
      debugPrint('❌ [CALL REPO EXCEPTION] fetchTodayVoiceSessions failed: $e');
      return {'items': <Map<String, dynamic>>[], 'total': 0, 'page': page, 'has_more': false};
    }
  }

  Future<Map<String, dynamic>> fetchTodayMessages({int page = 1, int limit = 10}) async {
    try {
      final String rawBase = AppConfig.baseUrl.endsWith('/')
          ? AppConfig.baseUrl.substring(0, AppConfig.baseUrl.length - 1)
          : AppConfig.baseUrl;
      final String endpointPath = rawBase.endsWith('/api/v1')
          ? '/conversations/today/messages'
          : '/api/v1/conversations/today/messages';
      final uri = Uri.parse('$rawBase$endpointPath?page=$page&limit=$limit');

      debugPrint('📡 [CALL REPO] GET Today Messages Paginated: $uri');

      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final List<dynamic> rawItems = decoded['items'] as List<dynamic>? ?? [];
          final items = rawItems.map((item) => Map<String, dynamic>.from(item as Map)).toList();
          return {
            'items': items,
            'total_items': decoded['total_items'] ?? items.length,
            'page': decoded['page'] ?? page,
            'limit': decoded['limit'] ?? limit,
            'total_pages': decoded['total_pages'] ?? 1,
          };
        }
      }
      return {'items': <Map<String, dynamic>>[], 'total_items': 0, 'page': page, 'limit': limit, 'total_pages': 1};
    } catch (e) {
      debugPrint('❌ [CALL REPO EXCEPTION] fetchTodayMessages failed: $e');
      return {'items': <Map<String, dynamic>>[], 'total_items': 0, 'page': page, 'limit': limit, 'total_pages': 1};
    }
  }

  Future<Map<String, dynamic>?> fetchConversationById(String conversationId) async {
    try {
      final String rawBase = AppConfig.baseUrl.endsWith('/')
          ? AppConfig.baseUrl.substring(0, AppConfig.baseUrl.length - 1)
          : AppConfig.baseUrl;
      final String endpointPath = rawBase.endsWith('/api/v1')
          ? '/conversations/$conversationId'
          : '/api/v1/conversations/$conversationId';
      final uri = Uri.parse('$rawBase$endpointPath');

      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return Map<String, dynamic>.from(decoded);
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ [CALL REPO EXCEPTION] fetchConversationById failed: $e');
      return null;
    }
  }

  void connect(String sessionId) {
    if (_isConnected) return;

    final wsBase = AppConfig.wsUrl.endsWith('/')
        ? AppConfig.wsUrl.substring(0, AppConfig.wsUrl.length - 1)
        : AppConfig.wsUrl;
    final uri = Uri.parse('$wsBase/api/v1/call/ws/$sessionId');
    debugPrint('🔌 [CALL REPO] Connecting WebSocket: $uri');

    try {
      _channel = WebSocketChannel.connect(uri);
      _isConnected = true;

      _subscription = _channel!.stream.listen(
        (data) {
          if (data is Uint8List) {
            debugPrint('🎧 [CALL REPO <- WS Audio] Received ${data.length} audio bytes');
            _audioStreamController.add(data);
          } else if (data is List<int>) {
            final bytes = Uint8List.fromList(data);
            debugPrint('🎧 [CALL REPO <- WS Audio] Received ${bytes.length} audio bytes');
            _audioStreamController.add(bytes);
          } else if (data is String) {
            try {
              final jsonMap = jsonDecode(data) as Map<String, dynamic>;
              debugPrint('📩 [CALL REPO <- WS Event] ${jsonMap['type']}: $jsonMap');
              _eventController.add(jsonMap);
            } catch (_) {
              debugPrint('📩 [CALL REPO <- WS Raw Text] $data');
            }
          }
        },
        onError: (error) {
          debugPrint('❌ [CALL REPO ERROR] WebSocket error: $error');
          _eventController.add({
            'type': 'error',
            'message': error.toString(),
          });
          _isConnected = false;
        },
        onDone: () {
          debugPrint('🔌 [CALL REPO DISCONNECTED] WebSocket closed.');
          _isConnected = false;
          _eventController.add({'type': 'disconnected'});
        },
      );

      sendJson({'type': 'start_call'});
    } catch (e) {
      debugPrint('❌ [CALL REPO EXCEPTION] Failed to connect: $e');
      _isConnected = false;
      _eventController.add({
        'type': 'error',
        'message': 'Failed to connect: $e',
      });
    }
  }

  void sendAudioChunk(Uint8List bytes) {
    if (_channel != null && _isConnected) {
      debugPrint('🎙️ [CALL REPO -> WS Audio] Sending ${bytes.length} mic bytes');
      _channel!.sink.add(bytes);
    }
  }

  void sendUserTranscript(String text) {
    debugPrint('💬 [CALL REPO -> WS Transcript] Sending: "$text"');
    sendJson({
      'type': 'user_transcript',
      'text': text,
    });
  }

  void sendInterrupt() {
    debugPrint('⚡ [CALL REPO -> WS Interrupt]');
    sendJson({'type': 'user_interrupted'});
  }

  void sendJson(Map<String, dynamic> payload) {
    if (_channel != null && _isConnected) {
      _channel!.sink.add(jsonEncode(payload));
    }
  }

  void disconnect({int? durationSeconds}) {
    if (_isConnected) {
      final payload = <String, dynamic>{'type': 'end_call'};
      if (durationSeconds != null && durationSeconds > 0) {
        payload['duration_seconds'] = durationSeconds;
      }
      sendJson(payload);
    }
    _subscription?.cancel();
    _channel?.sink.close();
    _isConnected = false;
  }

  void dispose() {
    disconnect();
    _eventController.close();
    _audioStreamController.close();
  }
}
