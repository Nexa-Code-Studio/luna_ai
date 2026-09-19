import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../../config/app_config.dart';

/// WebSocket client for Hybrid Half-Duplex AI Voice Call protocol.
class VoiceCallWsClient {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  bool _isConnected = false;

  final StreamController<Map<String, dynamic>> _eventController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Uint8List> _audioController =
      StreamController<Uint8List>.broadcast();

  Stream<Map<String, dynamic>> get eventStream => _eventController.stream;
  Stream<Uint8List> get audioStream => _audioController.stream;
  bool get isConnected => _isConnected;

  Future<void> connect(String sessionId) async {
    if (_isConnected) return;

    final wsBase = AppConfig.wsUrl.endsWith('/')
        ? AppConfig.wsUrl.substring(0, AppConfig.wsUrl.length - 1)
        : AppConfig.wsUrl;
    final token = await AppConfig.getToken();
    final uriStr = (token != null && token.isNotEmpty)
        ? '$wsBase/call/ws/$sessionId?token=$token'
        : '$wsBase/call/ws/$sessionId';
    final uri = Uri.parse(uriStr);
    debugPrint('🔌 [WS CLIENT] Connecting: $uri');

    try {
      _channel = WebSocketChannel.connect(uri);
      _isConnected = true;

      _subscription = _channel!.stream.listen(
        (data) {
          if (data is Uint8List) {
            _audioController.add(data);
          } else if (data is List<int>) {
            _audioController.add(Uint8List.fromList(data));
          } else if (data is String) {
            try {
              final jsonMap = jsonDecode(data) as Map<String, dynamic>;
              debugPrint('📩 [WS CLIENT <- EVENT] ${jsonMap['type']}');

              // If audio_chunk contains base64 audio, decode and forward to audioStream
              if (jsonMap['type'] == 'ai.audio_chunk' && jsonMap.containsKey('audio_base64')) {
                final b64 = jsonMap['audio_base64'] as String?;
                if (b64 != null && b64.isNotEmpty) {
                  try {
                    final bytes = base64Decode(b64);
                    _audioController.add(Uint8List.fromList(bytes));
                  } catch (e) {
                    debugPrint('⚠️ [WS CLIENT BASE64 ERROR]: $e');
                  }
                }
              }

              _eventController.add(jsonMap);
            } catch (e) {
              debugPrint('⚠️ [WS CLIENT JSON DECODE ERROR]: $e');
            }
          }
        },
        onError: (error) {
          debugPrint('❌ [WS CLIENT ERROR]: $error');
          _isConnected = false;
          _eventController.add({
            'type': 'error',
            'message': error.toString(),
          });
        },
        onDone: () {
          debugPrint('🔌 [WS CLIENT CLOSED]');
          _isConnected = false;
          _eventController.add({'type': 'disconnected'});
        },
      );
    } catch (e) {
      debugPrint('❌ [WS CLIENT EXCEPTION]: $e');
      _isConnected = false;
      _eventController.add({
        'type': 'error',
        'message': e.toString(),
      });
    }
  }

  void _sendJson(Map<String, dynamic> payload) {
    if (_channel != null && _isConnected) {
      _channel!.sink.add(jsonEncode(payload));
    }
  }

  void sendStartCall() {
    _sendJson({'type': 'start_call'});
  }

  void sendPartial({
    required String callId,
    required int userTurnId,
    required int sttSessionId,
    required int sequence,
    required String text,
  }) {
    _sendJson({
      'type': 'stt.partial',
      'call_id': callId,
      'user_turn_id': userTurnId,
      'stt_session_id': sttSessionId,
      'sequence': sequence,
      'text': text,
    });
  }

  void sendFinalSegment({
    required String callId,
    required int userTurnId,
    required int sttSessionId,
    required int sequence,
    required String text,
  }) {
    _sendJson({
      'type': 'stt.final_segment',
      'call_id': callId,
      'user_turn_id': userTurnId,
      'stt_session_id': sttSessionId,
      'sequence': sequence,
      'text': text,
    });
  }

  void sendStatus({
    required String callId,
    required int userTurnId,
    required int sttSessionId,
    required String status,
  }) {
    _sendJson({
      'type': 'stt.status',
      'status': status,
      'call_id': callId,
      'user_turn_id': userTurnId,
      'stt_session_id': sttSessionId,
    });
  }

  void sendInterrupt({
    required String callId,
    required int assistantTurnId,
    String reason = 'user_barge_in',
  }) {
    _sendJson({
      'type': 'assistant.interrupt',
      'call_id': callId,
      'assistant_turn_id': assistantTurnId,
      'reason': reason,
    });
    // Legacy interrupt for backward compatibility
    _sendJson({'type': 'user_interrupted'});
  }

  void sendPlaybackFinished({
    required String callId,
    required int assistantTurnId,
  }) {
    _sendJson({
      'type': 'playback.finished',
      'call_id': callId,
      'assistant_turn_id': assistantTurnId,
    });
  }

  void sendForceCommit({
    required String callId,
    required int userTurnId,
  }) {
    _sendJson({
      'type': 'user.force_commit',
      'call_id': callId,
      'user_turn_id': userTurnId,
    });
  }

  void sendSync({
    required String callId,
    required String knownState,
    required int userTurnId,
    required int assistantTurnId,
  }) {
    _sendJson({
      'type': 'call.sync',
      'call_id': callId,
      'known_state': knownState,
      'user_turn_id': userTurnId,
      'assistant_turn_id': assistantTurnId,
    });
  }

  void sendEndCall(int durationSeconds) {
    _sendJson({
      'type': 'end_call',
      'duration_seconds': durationSeconds,
    });
  }

  void disconnect() {
    _subscription?.cancel();
    _channel?.sink.close();
    _isConnected = false;
  }

  void dispose() {
    disconnect();
    _eventController.close();
    _audioController.close();
  }
}
