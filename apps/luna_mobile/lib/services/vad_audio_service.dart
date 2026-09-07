import 'dart:async';
import 'dart:math';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Representation of Voice Activity Detection (VAD) States
enum VadState {
  idle,
  listening,
  userSpeaking,
  aiProcessing,
  aiSpeaking,
  bargeInInterrupted,
}

/// Service for handling Voice Activity Detection (VAD), Real Microphone STT,
/// Decibel Amplitude Streams, Silence Detection, and Barge-In Interruption.
class VadAudioService {
  static final VadAudioService _instance = VadAudioService._internal();
  factory VadAudioService() => _instance;
  VadAudioService._internal();

  VadState _currentState = VadState.idle;
  bool _isMuted = false;
  final double _speechThresholdDb = 0.35;
  final int _silenceDurationMs = 1000;

  final StreamController<VadState> _vadStateController =
      StreamController<VadState>.broadcast();
  final StreamController<double> _amplitudeController =
      StreamController<double>.broadcast();
  final StreamController<String> _transcriptController =
      StreamController<String>.broadcast();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isSpeechInitialized = false;

  Timer? _amplitudeSimTimer;
  Timer? _silenceTimer;

  // Getters
  VadState get currentState => _currentState;
  bool get isMuted => _isMuted;
  double get speechThresholdDb => _speechThresholdDb;
  int get silenceDurationMs => _silenceDurationMs;

  Stream<VadState> get vadStateStream => _vadStateController.stream;
  Stream<double> get audioAmplitudeStream => _amplitudeController.stream;
  Stream<String> get transcriptStream => _transcriptController.stream;

  /// Initialize real mic listening or fallback to simulation
  Future<void> startListening() async {
    _currentState = VadState.listening;
    _vadStateController.add(_currentState);

    try {
      if (!_isSpeechInitialized) {
        _isSpeechInitialized = await _speech.initialize(
          onStatus: (status) {
            if (status == 'listening') {
              _setState(VadState.listening);
            } else if (status == 'notListening') {
              if (_currentState == VadState.userSpeaking) {
                _setState(VadState.aiProcessing);
              }
            }
          },
          onError: (_) {
            // In case of error, start simulation fallback
            _startAmplitudeSimulation();
          },
        );
      }

      if (_isSpeechInitialized) {
        await _speech.listen(
          listenOptions: stt.SpeechListenOptions(
            listenMode: stt.ListenMode.dictation,
            partialResults: true,
          ),
          onResult: (result) {
            if (result.recognizedWords.isNotEmpty) {
              _setState(VadState.userSpeaking);
              if (result.finalResult) {
                _transcriptController.add(result.recognizedWords);
                _setState(VadState.aiProcessing);
              }
            }
          },
          onSoundLevelChange: (level) {
            if (!_isMuted) {
              // Normalize level (typically -10 to 10 or 0 to 100)
              final normalized = ((level + 10) / 30.0).clamp(0.05, 1.0);
              _amplitudeController.add(normalized);
            }
          },
        );
      } else {
        _startAmplitudeSimulation();
      }
    } catch (_) {
      _startAmplitudeSimulation();
    }
  }

  /// Stop listening
  void stopListening() {
    _amplitudeSimTimer?.cancel();
    _silenceTimer?.cancel();
    try {
      if (_speech.isListening) {
        _speech.stop();
      }
    } catch (_) {}

    _currentState = VadState.idle;
    _vadStateController.add(_currentState);
    _amplitudeController.add(0.0);
  }

  /// Toggle microphone mute
  bool toggleMute() {
    _isMuted = !_isMuted;
    if (_isMuted) {
      _amplitudeController.add(0.0);
      try {
        if (_speech.isListening) _speech.stop();
      } catch (_) {}
    } else {
      if (_currentState == VadState.listening || _currentState == VadState.userSpeaking) {
        startListening();
      }
    }
    return _isMuted;
  }

  void _setState(VadState state) {
    if (_currentState != state) {
      _currentState = state;
      _vadStateController.add(_currentState);
    }
  }

  void setAiSpeaking() {
    _setState(VadState.aiSpeaking);
  }

  void setAiThinking() {
    _setState(VadState.aiProcessing);
  }

  void setIdle() {
    _setState(VadState.idle);
  }

  void setListening() {
    _setState(VadState.listening);
  }

  /// Simulate Speech Start (for tap button or manual trigger)
  void triggerSpeechStart() {
    if (_isMuted) return;
    _silenceTimer?.cancel();

    if (_currentState == VadState.aiSpeaking) {
      _setState(VadState.bargeInInterrupted);
      Timer(const Duration(milliseconds: 400), () {
        _setState(VadState.userSpeaking);
      });
    } else {
      _setState(VadState.userSpeaking);
    }
  }

  /// Simulate Speech Pause
  void triggerSpeechPause([String? text]) {
    if (_currentState != VadState.userSpeaking) return;
    _silenceTimer?.cancel();
    _silenceTimer = Timer(Duration(milliseconds: _silenceDurationMs), () {
      _setState(VadState.aiProcessing);
      _amplitudeController.add(0.0);
      _transcriptController.add(
        text ?? 'Halo LUNA, aku ingin bercerita tentang apa yang aku rasakan hari ini.',
      );
    });
  }

  void _startAmplitudeSimulation() {
    _amplitudeSimTimer?.cancel();
    final random = Random();
    _amplitudeSimTimer =
        Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (_isMuted) return;
      double amplitude = 0.05;
      if (_currentState == VadState.userSpeaking) {
        amplitude = 0.45 + (random.nextDouble() * 0.50);
      } else if (_currentState == VadState.aiSpeaking) {
        amplitude = 0.35 + (random.nextDouble() * 0.45);
      } else if (_currentState == VadState.listening) {
        amplitude = 0.05 + (random.nextDouble() * 0.12);
      }
      _amplitudeController.add(amplitude);
    });
  }
}
