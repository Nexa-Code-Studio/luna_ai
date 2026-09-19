import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Service managing real client-side Speech-To-Text transcription with tuned ChatGPT-style parameters.
class SttService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;
  bool _shouldKeepListening = false;
  Timer? _restartTimer;

  final StreamController<String> _transcriptController =
      StreamController<String>.broadcast();

  Stream<String> get transcriptStream => _transcriptController.stream;
  bool get isListening => _speechToText.isListening;
  bool get isInitialized => _isInitialized;

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    try {
      _isInitialized = await _speechToText.initialize(
        onError: (errorNotification) {
          debugPrint('⚠️ [STT ERROR]: ${errorNotification.errorMsg}');
          if (_shouldKeepListening) {
            _scheduleAutoRestart();
          }
        },
        onStatus: (status) {
          debugPrint('🎙️ [STT STATUS]: $status');
          if ((status == 'done' || status == 'notListening') && _shouldKeepListening) {
            _scheduleAutoRestart();
          }
        },
      );
      debugPrint('🎙️ [STT INIT SUCCESS]: $_isInitialized');
    } catch (e) {
      debugPrint('❌ [STT INIT EXCEPTION]: $e');
      _isInitialized = false;
    }
    return _isInitialized;
  }

  void _scheduleAutoRestart() {
    _restartTimer?.cancel();
    if (!_shouldKeepListening) return;
    _restartTimer = Timer(const Duration(milliseconds: 400), () {
      if (_shouldKeepListening && !_speechToText.isListening) {
        debugPrint('🔄 [STT AUTO RESTART]: Restarting speech recognizer listener...');
        startListening();
      }
    });
  }

  Future<void> startListening({void Function(String transcript)? onResult}) async {
    _shouldKeepListening = true;
    if (!_isInitialized) {
      await initialize();
    }
    if (!_isInitialized) {
      debugPrint('⚠️ [STT SERVICE]: SpeechToText not available or mic permission denied.');
      return;
    }

    if (_speechToText.isListening) return;

    try {
      await _speechToText.listen(
        onResult: (result) {
          final recognizedWords = result.recognizedWords;
          debugPrint('🎙️ [REAL STT RECOGNIZED]: "$recognizedWords" (final: ${result.finalResult})');
          if (recognizedWords.isNotEmpty) {
            emitTranscript(recognizedWords);
            if (onResult != null) {
              onResult(recognizedWords);
            }
          }
        },
        listenOptions: SpeechListenOptions(
          localeId: 'id_ID',
          listenFor: const Duration(seconds: 60),
          pauseFor: const Duration(seconds: 5),
          partialResults: true,
          cancelOnError: false,
          listenMode: ListenMode.dictation,
        ),
      );
    } catch (e) {
      debugPrint('❌ [STT LISTEN EXCEPTION]: $e');
      if (_shouldKeepListening) {
        _scheduleAutoRestart();
      }
    }
  }

  Future<void> stopListening() async {
    _shouldKeepListening = false;
    _restartTimer?.cancel();
    if (_speechToText.isListening) {
      try {
        await _speechToText.stop();
      } catch (e) {
        debugPrint('⚠️ [STT STOP EXCEPTION]: $e');
      }
    }
  }

  void emitTranscript(String text) {
    if (text.isNotEmpty) {
      _transcriptController.add(text);
    }
  }

  void dispose() {
    stopListening();
    _transcriptController.close();
  }
}
