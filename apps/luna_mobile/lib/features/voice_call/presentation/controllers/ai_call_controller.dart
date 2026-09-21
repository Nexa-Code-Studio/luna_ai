import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/call_config.dart';
import '../../data/datasources/voice_call_ws_client.dart';
import '../../data/services/ai_audio_playback_service.dart';
import '../../data/services/speech_recognition_service.dart';
import '../../domain/entities/call_state.dart';
import 'ai_call_state.dart';

class AiCallController extends StateNotifier<AiCallViewState> {
  final SpeechRecognitionService _speechService;
  final AiAudioPlaybackService _audioPlaybackService;
  final VoiceCallWsClient _wsClient;

  AiCallController({
    required SpeechRecognitionService speechService,
    required AiAudioPlaybackService audioPlaybackService,
    required VoiceCallWsClient wsClient,
  })  : _speechService = speechService,
        _audioPlaybackService = audioPlaybackService,
        _wsClient = wsClient,
        super(const AiCallViewState());

  StreamSubscription? _partialSubscription;
  StreamSubscription? _finalSegmentSubscription;
  StreamSubscription? _statusSubscription;
  StreamSubscription? _soundLevelSubscription;
  StreamSubscription? _aiAudioSoundSubscription;
  StreamSubscription? _playbackSubscription;
  StreamSubscription? _wsEventSubscription;
  StreamSubscription? _wsAudioSubscription;
  StreamSubscription? _errorSubscription;
  Timer? _durationTimer;
  Timer? _restartTimer;
  Timer? _thinkingWatchdogTimer;
  bool _isDisposed = false;
  int _restartAttempts = 0;

  Future<void> startCall({String? customCallId}) async {
    final callId = customCallId ?? 'call_${DateTime.now().millisecondsSinceEpoch}';
    debugPrint('🚀 [AI CALL CONTROLLER] Starting call: $callId');

    state = state.copyWith(
      callId: callId,
      callState: CallState.idle,
      userTurnId: 1,
      assistantTurnId: 0,
      activeSttSessionId: 0,
      currentTranscript: '',
      aiTranscript: '',
      callDurationSeconds: 0,
      clearError: true,
      clearCrisis: true,
    );

    _initSubscriptions();

    // 1. Initialize Speech Recognizer
    await _speechService.initialize();

    // 2. Connect WebSocket
    await _wsClient.connect(callId);
    _wsClient.sendStartCall();

    // 3. Start Duration Timer
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isDisposed && state.callState != CallState.ended) {
        state = state.copyWith(callDurationSeconds: state.callDurationSeconds + 1);
      }
    });

    // 4. Initial transition to LISTENING
    await enterListening();
  }

  void _initSubscriptions() {
    _cancelSubscriptions();

    // STT Partial transcript
    _partialSubscription = _speechService.partialStream.listen((partial) {
      if (state.callState != CallState.listening) return;
      if (partial.sttSessionId != state.activeSttSessionId) return;

      state = state.copyWith(
        latestPartial: partial.text,
        isUserSpeaking: true,
      );

      _wsClient.sendPartial(
        callId: state.callId,
        userTurnId: state.userTurnId,
        sttSessionId: partial.sttSessionId,
        sequence: partial.sequence,
        text: partial.text,
      );
    });

    // STT Final Segment
    _finalSegmentSubscription = _speechService.finalSegmentStream.listen((seg) {
      if (state.callState != CallState.listening) return;
      if (seg.sttSessionId != state.activeSttSessionId) return;

      state = state.copyWith(
        currentTranscript: seg.text,
        latestPartial: '',
        isUserSpeaking: true,
      );

      _wsClient.sendFinalSegment(
        callId: state.callId,
        userTurnId: state.userTurnId,
        sttSessionId: seg.sttSessionId,
        sequence: seg.sequence,
        text: seg.text,
      );
    });

    // STT Status
    _statusSubscription = _speechService.statusStream.listen((statusEvent) {
      if (statusEvent.sttSessionId != state.activeSttSessionId) return;

      _wsClient.sendStatus(
        callId: state.callId,
        userTurnId: state.userTurnId,
        sttSessionId: statusEvent.sttSessionId,
        status: statusEvent.status,
      );
    });

    // Sound Level
    _soundLevelSubscription = _speechService.soundLevelStream.listen((level) {
      if (!_isDisposed) {
        state = state.copyWith(soundLevel: level);
      }
    });

    // Error stream
    _errorSubscription = _speechService.errorStream.listen((err) {
      debugPrint('⚠️ [STT SERVICE ERROR]: $err');
      // If listening unexpectedly stopped and recoverable, notify status
      if (state.callState == CallState.listening) {
        _wsClient.sendStatus(
          callId: state.callId,
          userTurnId: state.userTurnId,
          sttSessionId: state.activeSttSessionId,
          status: 'error_$err',
        );
      }
    });

    // Playback Completed (Queue completely empty)
    _playbackSubscription = _audioPlaybackService.onPlaybackCompleted.listen((turnId) {
      handlePlaybackFinished(turnId);
    });

    // AI Audio Playback Sound Level (real-time envelope intonation)
    _aiAudioSoundSubscription = _audioPlaybackService.soundLevelStream.listen((level) {
      if (state.callState == CallState.aiSpeaking) {
        state = state.copyWith(soundLevel: level);
      }
    });

    // WebSocket Incoming Audio Chunks
    _wsAudioSubscription = _wsClient.audioStream.listen((audioBytes) {
      if (state.callState != CallState.aiSpeaking) {
        enterAiSpeaking(state.assistantTurnId);
      }
      _audioPlaybackService.enqueueChunk(
        bytes: audioBytes,
        assistantTurnId: state.assistantTurnId,
        sequence: 0,
      );
    });

    // WebSocket Incoming Events
    _wsEventSubscription = _wsClient.eventStream.listen((event) {
      handleSocketEvent(event);
    });
  }

  void handleSocketEvent(Map<String, dynamic> event) {
    final type = event['type'] as String?;
    if (type == null) return;

    debugPrint('📩 [AI CALL CONTROLLER <- WS] $type');

    if (type == 'turn.keep_open') {
      final restart = event['restart_stt'] as bool? ?? false;
      final waitMs = (event['wait_ms'] as num?)?.toInt() ?? CallConfig.sttRestartDelayMs;
      // If we were waiting in thinking (e.g. from empty force commit), recover to listening immediately
      if (state.callState == CallState.thinking) {
        enterListening();
      } else {
        handleKeepOpen(restart, waitMs);
      }
    } else if (type == 'turn.committed') {
      final finalTranscript = event['final_transcript'] as String? ?? '';
      state = state.copyWith(currentTranscript: finalTranscript);
      enterThinking();
    } else if (type == 'ai.thinking' || type == 'ai_thinking') {
      final turnId = (event['assistant_turn_id'] as num?)?.toInt();
      if (turnId != null) {
        state = state.copyWith(assistantTurnId: turnId);
      }
      enterThinking();
    } else if (type == 'ai.transcript_chunk' || type == 'ai_transcript_chunk') {
      final text = event['text'] as String? ?? '';
      // Set full transcript if incoming chunk contains complete response, or append if chunked
      state = state.copyWith(
        aiTranscript: text.length >= state.aiTranscript.length ? text : (state.aiTranscript + text),
      );
    } else if (type == 'ai.audio_chunk' || type == 'ai_audio_chunk') {
      final turnId = (event['assistant_turn_id'] as num?)?.toInt() ?? state.assistantTurnId;
      final seq = (event['sequence'] as num?)?.toInt() ?? 0;
      final b64 = event['audio_base64'] as String?;
      final envelope = (event['envelope'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList() ?? <double>[];

      if (b64 != null && b64.isNotEmpty) {
        try {
          final audioBytes = base64Decode(b64);
          if (state.callState != CallState.aiSpeaking) {
            enterAiSpeaking(turnId);
          }
          _audioPlaybackService.enqueueChunk(
            bytes: audioBytes,
            assistantTurnId: turnId,
            sequence: seq,
            envelope: envelope,
          );
        } catch (e) {
          debugPrint('⚠️ [AI AUDIO DECODE ERROR]: $e');
        }
      }
    } else if (type == 'ai.speech_finished' || type == 'ai_speech_finished') {
      final turnId = (event['assistant_turn_id'] as num?)?.toInt() ?? state.assistantTurnId;
      if (state.callState == CallState.thinking) {
        // Backend finished generation but no audio was enqueued/played (TTS fallback/text-only)
        _thinkingWatchdogTimer?.cancel();
        Future.delayed(const Duration(milliseconds: 1500), () async {
          if (state.callState == CallState.thinking && !_isDisposed) {
            state = state.copyWith(userTurnId: state.userTurnId + 1);
            await enterListening();
          }
        });
      } else {
        _audioPlaybackService.markStreamFinished(turnId);
      }
    } else if (type == 'assistant.interrupted_ack' || type == 'interrupted_ack') {
      debugPrint('⚡ [AI CALL CONTROLLER] Interrupted ACK confirmed by server');
    } else if (type == 'call.sync_state') {
      final activeUserTurn = (event['active_user_turn_id'] as num?)?.toInt();
      final activeAssistantTurn = (event['active_assistant_turn_id'] as num?)?.toInt();
      final serverState = event['state'] as String?;
      if (activeUserTurn != null) {
        state = state.copyWith(userTurnId: activeUserTurn);
      }
      if (activeAssistantTurn != null) {
        state = state.copyWith(assistantTurnId: activeAssistantTurn);
      }
      if (serverState == 'listening' && state.callState == CallState.thinking) {
        enterListening();
      }
    } else if (type == 'ai.crisis_escalation' || type == 'crisis_alert' || type == 'emergency_triggered') {
      final hotline = event['hotline'] as String? ?? 'Hotline Dinkes (WhatsApp 0813-8007-3120) / Kemenkes 119 ext 8';
      final hotlineUrl = event['hotline_url'] as String? ??
          'https://api.whatsapp.com/send/?phone=6281380073120&text=halo%20kak%2C%20saya%20ingin%20bercerita%20mengenai...&type=phone_number&app_absent=0';
      state = state.copyWith(
        crisisHotline: hotline,
        crisisHotlineUrl: hotlineUrl,
        isCrisisSession: true,
      );
    } else if (type == 'error') {
      state = state.copyWith(errorMessage: event['message'] as String? ?? 'Terjadi kesalahan sistem');
      if (state.callState == CallState.thinking || state.callState == CallState.aiSpeaking) {
        enterListening();
      }
    }
  }

  /// Invariant: LISTENING -> STT ON, AI audio OFF
  Future<void> enterListening() async {
    _restartTimer?.cancel();
    _thinkingWatchdogTimer?.cancel();

    // Guard: Audio must be completely stopped before mic opens
    await _audioPlaybackService.stop();

    final nextSessionId = state.activeSttSessionId + 1;
    _restartAttempts = 0;

    state = state.copyWith(
      callState: CallState.listening,
      activeSttSessionId: nextSessionId,
      isUserSpeaking: false,
      currentTranscript: '',
      latestPartial: '',
      aiTranscript: '',
    );

    if (state.conversationMode == ConversationMode.hybridAuto && !state.isMuted) {
      await _speechService.startListening(sttSessionId: nextSessionId);
    }
  }

  /// Invariant: THINKING -> STT OFF, AI audio OFF
  Future<void> enterThinking() async {
    _restartTimer?.cancel();
    _thinkingWatchdogTimer?.cancel();
    state = state.copyWith(
      callState: CallState.thinking,
      isUserSpeaking: false,
      soundLevel: 0.05,
    );
    await _speechService.stopListening();

    // Watchdog Timer: Guard against stuck thinking if backend stalls or drops connection
    _thinkingWatchdogTimer = Timer(const Duration(seconds: 15), () async {
      if (state.callState == CallState.thinking && !_isDisposed) {
        debugPrint('⚠️ [THINKING WATCHDOG TIMEOUT]: No AI response within 15s. Recovering to listening.');
        state = state.copyWith(
          errorMessage: 'Respons Luna membutuhkan waktu lebih lama. Silakan coba bicara lagi.',
        );
        await enterListening();
      }
    });
  }

  /// Invariant: AI_SPEAKING -> STT OFF, AI audio ON
  Future<void> enterAiSpeaking(int assistantTurnId) async {
    _restartTimer?.cancel();
    _thinkingWatchdogTimer?.cancel();
    state = state.copyWith(
      callState: CallState.aiSpeaking,
      assistantTurnId: assistantTurnId,
      isUserSpeaking: false,
      soundLevel: 0.05,
    );
    _audioPlaybackService.prepareNewAssistantTurn(assistantTurnId);
    await _speechService.stopListening();
  }

  /// Normal Automatic Flow: AI playback finished -> guard delay -> auto LISTENING
  Future<void> handlePlaybackFinished(int finishedTurnId) async {
    if (state.callState != CallState.aiSpeaking) return;

    debugPrint('🔊 [PLAYBACK FINISHED]: Guard delay before auto-listening...');
    _wsClient.sendPlaybackFinished(
      callId: state.callId,
      assistantTurnId: finishedTurnId,
    );

    // Guard delay between AI speaker end and mic start
    await Future.delayed(const Duration(milliseconds: CallConfig.playbackToListeningGuardMs));

    if (state.callState == CallState.aiSpeaking && !_isDisposed) {
      // Ensure userTurnId advances to at least finishedTurnId + 1 without duplicate double increment
      if (state.userTurnId <= finishedTurnId) {
        state = state.copyWith(userTurnId: finishedTurnId + 1);
      }
      await enterListening();
    }
  }

  /// Auto-restart STT on turn.keep_open if Android recognizer paused
  void handleKeepOpen(bool restartStt, int waitMs) {
    if (state.callState != CallState.listening) return;
    if (!restartStt) return;

    _restartAttempts++;
    if (_restartAttempts > 10) {
      debugPrint('⚠️ [AUTO RESTART]: Max restart limit reached. Awaiting timeout or manual commit.');
      return;
    }

    _restartTimer?.cancel();
    _restartTimer = Timer(const Duration(milliseconds: CallConfig.sttRestartDelayMs), () async {
      if (state.callState == CallState.listening && !_isDisposed && !state.isMuted) {
        final nextSessionId = state.activeSttSessionId + 1;
        debugPrint('🔄 [AUTO RESTART STT]: Session $nextSessionId in user_turn ${state.userTurnId}');
        state = state.copyWith(activeSttSessionId: nextSessionId);
        await _speechService.startListening(sttSessionId: nextSessionId);
      }
    });
  }

  /// Manual Barge-In: Interrupt ongoing AI response or pending generation
  Future<void> bargeIn() async {
    // Idempotent guard: if already interrupting or listening, ignore duplicate taps
    if (state.callState == CallState.interrupting || state.callState == CallState.listening) {
      debugPrint('⚡ [BARGE-IN IGNORED]: Already in state ${state.callState}');
      return;
    }

    debugPrint('⚡ [MANUAL BARGE-IN TRIGGERED] State: ${state.callState}');

    _thinkingWatchdogTimer?.cancel();
    state = state.copyWith(callState: CallState.interrupting);

    // 1. Instantly stop audio player locally and flush queue
    await _audioPlaybackService.stop();

    // 2. Notify backend to cancel active task
    _wsClient.sendInterrupt(
      callId: state.callId,
      assistantTurnId: state.assistantTurnId,
      reason: 'user_barge_in',
    );

    // 3. Short barge-in guard delay
    await Future.delayed(const Duration(milliseconds: CallConfig.bargeInGuardMs));

    if (!_isDisposed) {
      // 4. Create new user turn and start listening immediately
      state = state.copyWith(userTurnId: state.userTurnId + 1);
      await enterListening();
    }
  }

  /// Manual force-commit button in LISTENING state ("Selesai Bicara")
  Future<void> forceCommit() async {
    if (state.callState != CallState.listening) return;

    debugPrint('👆 [FORCE COMMIT] Turn: ${state.userTurnId}');
    _wsClient.sendForceCommit(
      callId: state.callId,
      userTurnId: state.userTurnId,
    );
    await enterThinking();
  }

  /// Toggle microphone mute
  void toggleMute() {
    final newMute = !state.isMuted;
    _speechService.setMuted(newMute);
    state = state.copyWith(isMuted: newMute);

    if (newMute) {
      _speechService.stopListening();
    } else if (state.callState == CallState.listening) {
      _speechService.startListening(sttSessionId: state.activeSttSessionId);
    }
  }

  /// Toggle speakerphone (Loudspeaker vs Earpiece)
  void toggleSpeaker() {
    final newSpeaker = !state.isSpeakerOn;
    state = state.copyWith(isSpeakerOn: newSpeaker);
    _audioPlaybackService.setSpeakerphoneOn(newSpeaker);
  }

  /// Switch conversation mode (Hybrid Auto vs Push to Talk fallback)
  void setConversationMode(ConversationMode mode) {
    state = state.copyWith(conversationMode: mode);
    if (mode == ConversationMode.pushToTalk && state.callState == CallState.listening) {
      _speechService.stopListening();
    } else if (mode == ConversationMode.hybridAuto && state.callState == CallState.listening) {
      _speechService.startListening(sttSessionId: state.activeSttSessionId);
    }
  }

  /// Push-to-talk press down: start listening
  Future<void> pushToTalkPress() async {
    if (state.conversationMode != ConversationMode.pushToTalk) return;
    if (state.callState == CallState.aiSpeaking || state.callState == CallState.thinking) {
      await bargeIn();
    } else if (state.callState == CallState.listening) {
      await _speechService.startListening(sttSessionId: state.activeSttSessionId);
    }
  }

  /// Push-to-talk release: stop listening & force commit
  Future<void> pushToTalkRelease() async {
    if (state.conversationMode != ConversationMode.pushToTalk) return;
    await forceCommit();
  }

  /// End Call & Disconnect
  Future<void> endCall() async {
    _durationTimer?.cancel();
    _restartTimer?.cancel();
    _thinkingWatchdogTimer?.cancel();

    await _speechService.stopListening();
    await _audioPlaybackService.stop();

    _wsClient.sendEndCall(state.callDurationSeconds);
    _wsClient.disconnect();

    state = state.copyWith(callState: CallState.ended);
  }

  void _cancelSubscriptions() {
    _partialSubscription?.cancel();
    _finalSegmentSubscription?.cancel();
    _statusSubscription?.cancel();
    _soundLevelSubscription?.cancel();
    _aiAudioSoundSubscription?.cancel();
    _playbackSubscription?.cancel();
    _wsAudioSubscription?.cancel();
    _wsEventSubscription?.cancel();
    _errorSubscription?.cancel();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _cancelSubscriptions();
    _durationTimer?.cancel();
    _restartTimer?.cancel();
    _thinkingWatchdogTimer?.cancel();
    _speechService.stopListening();
    _audioPlaybackService.stop();
    _wsClient.disconnect();
    super.dispose();
  }
}
