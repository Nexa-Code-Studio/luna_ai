import 'dart:async';

import 'dart:math';



/// Representation of Voice Activity Detection (VAD) States

enum VadState {

  /// System is uninitialized or stopped

  idle,



  /// Microphone active, listening for human voice input

  listening,



  /// Human speech detected (VAD active, amplitude > speech threshold)

  userSpeaking,



  /// Speech pause detected (>1000ms silence), processing AI response

  aiProcessing,



  /// LUNA AI audio output is playing back

  aiSpeaking,



  /// User started speaking while LUNA was talking (Barge-In Interrupt triggered)

  bargeInInterrupted,

}



/// Service for handling Voice Activity Detection (VAD), Audio Decibel Amplitude Streams,

/// Silence Threshold Detection, and Barge-In Interruption capabilities.

class VadAudioService {

  // Singleton instance

  static final VadAudioService _instance = VadAudioService._internal();

  factory VadAudioService() => _instance;

  VadAudioService._internal();



  VadState _currentState = VadState.idle;

  bool _isMuted = false;

  double _speechThresholdDb = 0.35; // 35% amplitude threshold to trigger speech

  int _silenceDurationMs = 1000; // 1 second silence triggers end-of-speech



  final StreamController<VadState> _vadStateController =

      StreamController<VadState>.broadcast();

  final StreamController<double> _amplitudeController =

      StreamController<double>.broadcast();



  Timer? _amplitudeSimTimer;

  Timer? _silenceTimer;



  // Getters

  VadState get currentState => _currentState;

  bool get isMuted => _isMuted;

  double get speechThresholdDb => _speechThresholdDb;

  int get silenceDurationMs => _silenceDurationMs;



  Stream<VadState> get vadStateStream => _vadStateController.stream;

  Stream<double> get audioAmplitudeStream => _amplitudeController.stream;



  /// Initialize VAD listening mode

  void startListening() {

    _currentState = VadState.listening;

    _vadStateController.add(_currentState);

    _startAmplitudeSimulation();

  }



  /// Stop VAD listening mode

  void stopListening() {

    _amplitudeSimTimer?.cancel();

    _silenceTimer?.cancel();

    _currentState = VadState.idle;

    _vadStateController.add(_currentState);

    _amplitudeController.add(0.0);

  }



  /// Toggle microphone mute

  bool toggleMute() {

    _isMuted = !_isMuted;

    if (_isMuted) {

      _amplitudeController.add(0.0);

    }

    return _isMuted;

  }



  /// Update VAD parameters

  void configure({double? speechThresholdDb, int? silenceDurationMs}) {

    if (speechThresholdDb != null) _speechThresholdDb = speechThresholdDb;

    if (silenceDurationMs != null) _silenceDurationMs = silenceDurationMs;

  }



  /// Simulate Human Speech Input Start (VAD active)

  void triggerSpeechStart() {

    if (_isMuted) return;



    _silenceTimer?.cancel();



    // Check for Barge-In Interruption if LUNA was currently speaking!

    if (_currentState == VadState.aiSpeaking) {

      _currentState = VadState.bargeInInterrupted;

      _vadStateController.add(_currentState);



      // Brief delay before switching to userSpeaking

      Timer(const Duration(milliseconds: 400), () {

        _currentState = VadState.userSpeaking;

        _vadStateController.add(_currentState);

      });

    } else {

      _currentState = VadState.userSpeaking;

      _vadStateController.add(_currentState);

    }

  }



  /// Simulate Human Speech Pause (triggers silence threshold countdown)

  void triggerSpeechPause() {

    if (_currentState != VadState.userSpeaking) return;



    _silenceTimer?.cancel();

    _silenceTimer = Timer(Duration(milliseconds: _silenceDurationMs), () {

      // Silence threshold reached -> Switch to AI Processing

      _currentState = VadState.aiProcessing;

      _vadStateController.add(_currentState);

      _amplitudeController.add(0.0);



      // Simulate AI starting to speak after 1.2s processing

      Timer(const Duration(milliseconds: 1200), () {

        if (_currentState == VadState.aiProcessing) {

          _currentState = VadState.aiSpeaking;

          _vadStateController.add(_currentState);

        }

      });

    });

  }



  /// Trigger LUNA AI finished speaking -> return to listening

  void finishAiSpeaking() {

    if (_currentState == VadState.aiSpeaking) {

      _currentState = VadState.listening;

      _vadStateController.add(_currentState);

    }

  }



  /// Real-time Amplitude Generator Simulation (Emulates mic input decibels)

  void _startAmplitudeSimulation() {

    _amplitudeSimTimer?.cancel();

    final random = Random();



    _amplitudeSimTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {

      if (_isMuted) {

        _amplitudeController.add(0.0);

        return;

      }



      double amp = 0.05 + random.nextDouble() * 0.1; // Baseline ambient noise (5-15%)



      if (_currentState == VadState.userSpeaking) {

        // Active speech decibel boost (40% - 95%)

        amp = 0.40 + random.nextDouble() * 0.55;

      } else if (_currentState == VadState.aiSpeaking) {

        // AI audio playback amplitude (30% - 80%)

        amp = 0.30 + random.nextDouble() * 0.50;

      }



      _amplitudeController.add(amp);

    });

  }



  void dispose() {

    _amplitudeSimTimer?.cancel();

    _silenceTimer?.cancel();

    _vadStateController.close();

    _amplitudeController.close();

  }

}

