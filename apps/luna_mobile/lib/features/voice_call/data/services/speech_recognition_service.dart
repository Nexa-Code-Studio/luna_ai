import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SttPartialResult {
  final String text;
  final int sttSessionId;
  final int sequence;

  const SttPartialResult({
    required this.text,
    required this.sttSessionId,
    required this.sequence,
  });
}

class SttFinalResult {
  final String text;
  final int sttSessionId;
  final int sequence;

  const SttFinalResult({
    required this.text,
    required this.sttSessionId,
    required this.sequence,
  });
}

class SttStatusEvent {
  final String status;
  final int sttSessionId;

  const SttStatusEvent({
    required this.status,
    required this.sttSessionId,
  });
}

/// Service wrapping Flutter speech_to_text with strict STT session tracking and sequence numbers.
class SpeechRecognitionService {
  final stt.SpeechToText _speech;

  SpeechRecognitionService({stt.SpeechToText? speech})
      : _speech = speech ?? stt.SpeechToText();

  bool _isInitialized = false;
  int _activeSttSessionId = 0;
  int _sequenceCounter = 0;
  bool _isMuted = false;

  final StreamController<SttPartialResult> _partialController =
      StreamController<SttPartialResult>.broadcast();
  final StreamController<SttFinalResult> _finalSegmentController =
      StreamController<SttFinalResult>.broadcast();
  final StreamController<SttStatusEvent> _statusController =
      StreamController<SttStatusEvent>.broadcast();
  final StreamController<double> _soundLevelController =
      StreamController<double>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  Stream<SttPartialResult> get partialStream => _partialController.stream;
  Stream<SttFinalResult> get finalSegmentStream => _finalSegmentController.stream;
  Stream<SttStatusEvent> get statusStream => _statusController.stream;
  Stream<double> get soundLevelStream => _soundLevelController.stream;
  Stream<String> get errorStream => _errorController.stream;

  bool get isListening => _speech.isListening;
  bool get isInitialized => _isInitialized;
  int get activeSttSessionId => _activeSttSessionId;
  bool get isMuted => _isMuted;

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    try {
      _isInitialized = await _speech.initialize(
        onStatus: (status) {
          debugPrint('🎙️ [STT STATUS]: $status (active session: $_activeSttSessionId)');
          _statusController.add(SttStatusEvent(
            status: status,
            sttSessionId: _activeSttSessionId,
          ));
        },
        onError: (SpeechRecognitionError error) {
          debugPrint('⚠️ [STT ERROR]: ${error.errorMsg} (permanent: ${error.permanent})');
          _errorController.add(error.errorMsg);
        },
      );
      debugPrint('🎙️ [STT INITIALIZED]: $_isInitialized');
    } catch (e) {
      debugPrint('❌ [STT INIT EXCEPTION]: $e');
      _isInitialized = false;
    }
    return _isInitialized;
  }

  void setMuted(bool muted) {
    _isMuted = muted;
    if (_isMuted && _speech.isListening) {
      stopListening();
    }
  }

  Future<void> startListening({required int sttSessionId}) async {
    if (_isMuted) return;

    if (!_isInitialized) {
      final ok = await initialize();
      if (!ok) {
        _errorController.add('Speech recognizer initialization failed or permission denied');
        return;
      }
    }

    _activeSttSessionId = sttSessionId;
    _sequenceCounter = 0;

    if (_speech.isListening) {
      try {
        await _speech.stop();
      } catch (_) {}
    }

    try {
      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          // Strict session token validation: Drop callbacks from outdated STT sessions
          if (sttSessionId != _activeSttSessionId) {
            debugPrint('⚠️ [STT DISCARDED]: Callback session $sttSessionId != active $_activeSttSessionId');
            return;
          }

          final words = result.recognizedWords.trim();
          if (words.isEmpty) return;

          _sequenceCounter++;

          if (result.finalResult) {
            debugPrint('🎙️ [STT FINAL SEGMENT]: "$words" (session $sttSessionId, seq $_sequenceCounter)');
            _finalSegmentController.add(SttFinalResult(
              text: words,
              sttSessionId: sttSessionId,
              sequence: _sequenceCounter,
            ));
          } else {
            debugPrint('🎙️ [STT PARTIAL]: "$words" (session $sttSessionId, seq $_sequenceCounter)');
            _partialController.add(SttPartialResult(
              text: words,
              sttSessionId: sttSessionId,
              sequence: _sequenceCounter,
            ));
          }
        },
        onSoundLevelChange: (double level) {
          if (!_isMuted) {
            // Normalize level between 0.0 and 1.0 for visual equalizer
            final normalized = ((level + 10.0) / 30.0).clamp(0.05, 1.0);
            _soundLevelController.add(normalized);
          }
        },
        listenOptions: stt.SpeechListenOptions(
          localeId: 'id_ID',
          listenMode: stt.ListenMode.dictation,
          partialResults: true,
          cancelOnError: false,
        ),
      );
      debugPrint('🎙️ [STT STARTED]: Session $sttSessionId');
    } catch (e) {
      debugPrint('❌ [STT LISTEN EXCEPTION]: $e');
      _errorController.add('Listen failed: $e');
    }
  }

  Future<void> stopListening() async {
    try {
      if (_speech.isListening) {
        await _speech.stop();
      }
    } catch (e) {
      debugPrint('⚠️ [STT STOP EXCEPTION]: $e');
    }
    if (!_soundLevelController.isClosed) {
      _soundLevelController.add(0.0);
    }
  }

  Future<void> cancelListening() async {
    try {
      if (_speech.isListening) {
        await _speech.cancel();
      }
    } catch (e) {
      debugPrint('⚠️ [STT CANCEL EXCEPTION]: $e');
    }
    if (!_soundLevelController.isClosed) {
      _soundLevelController.add(0.0);
    }
  }

  void dispose() {
    try {
      if (_speech.isListening) {
        _speech.stop();
      }
    } catch (_) {}
    if (!_partialController.isClosed) _partialController.close();
    if (!_finalSegmentController.isClosed) _finalSegmentController.close();
    if (!_statusController.isClosed) _statusController.close();
    if (!_soundLevelController.isClosed) _soundLevelController.close();
    if (!_errorController.isClosed) _errorController.close();
  }
}
