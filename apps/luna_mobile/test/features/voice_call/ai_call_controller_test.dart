import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:luna_mobile/features/voice_call/data/datasources/voice_call_ws_client.dart';
import 'package:luna_mobile/features/voice_call/data/services/ai_audio_playback_service.dart';
import 'package:luna_mobile/features/voice_call/data/services/speech_recognition_service.dart';
import 'package:luna_mobile/features/voice_call/domain/entities/call_state.dart';
import 'package:luna_mobile/features/voice_call/presentation/controllers/ai_call_controller.dart';

class FakeSpeechRecognitionService extends Fake implements SpeechRecognitionService {
  @override
  bool isInitialized = false;
  @override
  bool isListening = false;
  int activeSessionId = 0;
  @override
  bool isMuted = false;

  final StreamController<SttPartialResult> partialController =
      StreamController<SttPartialResult>.broadcast();
  final StreamController<SttFinalResult> finalSegmentController =
      StreamController<SttFinalResult>.broadcast();
  final StreamController<SttStatusEvent> statusController =
      StreamController<SttStatusEvent>.broadcast();
  final StreamController<double> soundLevelController =
      StreamController<double>.broadcast();
  final StreamController<String> errorController =
      StreamController<String>.broadcast();

  @override
  Stream<SttPartialResult> get partialStream => partialController.stream;
  @override
  Stream<SttFinalResult> get finalSegmentStream => finalSegmentController.stream;
  @override
  Stream<SttStatusEvent> get statusStream => statusController.stream;
  @override
  Stream<double> get soundLevelStream => soundLevelController.stream;
  @override
  Stream<String> get errorStream => errorController.stream;

  @override
  Future<bool> initialize() async {
    isInitialized = true;
    return true;
  }

  @override
  Future<void> startListening({required int sttSessionId}) async {
    isListening = true;
    activeSessionId = sttSessionId;
  }

  @override
  Future<void> stopListening() async {
    isListening = false;
  }

  @override
  void setMuted(bool muted) {
    isMuted = muted;
    if (isMuted) isListening = false;
  }

  @override
  void dispose() {
    partialController.close();
    finalSegmentController.close();
    statusController.close();
    soundLevelController.close();
    errorController.close();
  }
}

class FakeAiAudioPlaybackService extends Fake implements AiAudioPlaybackService {
  @override
  bool isPlaying = false;
  int currentTurn = 0;
  final StreamController<int> playbackCompletedController =
      StreamController<int>.broadcast();

  @override
  Stream<int> get onPlaybackCompleted => playbackCompletedController.stream;

  @override
  void prepareNewAssistantTurn(int assistantTurnId) {
    currentTurn = assistantTurnId;
  }

  @override
  Future<void> stop() async {
    isPlaying = false;
  }

  @override
  void markStreamFinished(int assistantTurnId) {}

  @override
  void dispose() {
    playbackCompletedController.close();
  }
}

class FakeVoiceCallWsClient extends Fake implements VoiceCallWsClient {
  @override
  bool isConnected = false;
  final List<Map<String, dynamic>> sentEvents = [];
  final StreamController<Map<String, dynamic>> eventController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Uint8List> audioController =
      StreamController<Uint8List>.broadcast();

  @override
  Stream<Map<String, dynamic>> get eventStream => eventController.stream;
  @override
  Stream<Uint8List> get audioStream => audioController.stream;

  @override
  Future<void> connect(String sessionId) async {
    isConnected = true;
  }

  @override
  void sendStartCall() {
    sentEvents.add({'type': 'start_call'});
  }

  @override
  void sendPartial({
    required String callId,
    required int userTurnId,
    required int sttSessionId,
    required int sequence,
    required String text,
  }) {
    sentEvents.add({
      'type': 'stt.partial',
      'call_id': callId,
      'user_turn_id': userTurnId,
      'stt_session_id': sttSessionId,
      'sequence': sequence,
      'text': text,
    });
  }

  @override
  void sendFinalSegment({
    required String callId,
    required int userTurnId,
    required int sttSessionId,
    required int sequence,
    required String text,
  }) {
    sentEvents.add({
      'type': 'stt.final_segment',
      'call_id': callId,
      'user_turn_id': userTurnId,
      'stt_session_id': sttSessionId,
      'sequence': sequence,
      'text': text,
    });
  }

  @override
  void sendStatus({
    required String callId,
    required int userTurnId,
    required int sttSessionId,
    required String status,
  }) {
    sentEvents.add({
      'type': 'stt.status',
      'status': status,
      'call_id': callId,
      'user_turn_id': userTurnId,
      'stt_session_id': sttSessionId,
    });
  }

  @override
  void sendInterrupt({
    required String callId,
    required int assistantTurnId,
    String reason = 'user_barge_in',
  }) {
    sentEvents.add({
      'type': 'assistant.interrupt',
      'call_id': callId,
      'assistant_turn_id': assistantTurnId,
      'reason': reason,
    });
  }

  @override
  void sendPlaybackFinished({
    required String callId,
    required int assistantTurnId,
  }) {
    sentEvents.add({
      'type': 'playback.finished',
      'call_id': callId,
      'assistant_turn_id': assistantTurnId,
    });
  }

  @override
  void sendForceCommit({
    required String callId,
    required int userTurnId,
  }) {
    sentEvents.add({
      'type': 'user.force_commit',
      'call_id': callId,
      'user_turn_id': userTurnId,
    });
  }

  @override
  void sendEndCall(int durationSeconds) {
    sentEvents.add({
      'type': 'end_call',
      'duration_seconds': durationSeconds,
    });
  }

  @override
  void disconnect() {
    isConnected = false;
  }

  @override
  void dispose() {
    eventController.close();
    audioController.close();
  }
}

void main() {
  late FakeSpeechRecognitionService fakeSpeech;
  late FakeAiAudioPlaybackService fakeAudio;
  late FakeVoiceCallWsClient fakeWs;
  late AiCallController controller;

  setUp(() {
    fakeSpeech = FakeSpeechRecognitionService();
    fakeAudio = FakeAiAudioPlaybackService();
    fakeWs = FakeVoiceCallWsClient();
    controller = AiCallController(
      speechService: fakeSpeech,
      audioPlaybackService: fakeAudio,
      wsClient: fakeWs,
    );
  });

  tearDown(() {
    controller.dispose();
  });

  test('startCall initializes services and enters listening', () async {
    await controller.startCall(customCallId: 'test_call_101');

    expect(controller.state.callId, 'test_call_101');
    expect(controller.state.callState, CallState.listening);
    expect(controller.state.userTurnId, 1);
    expect(fakeSpeech.isListening, isTrue);
    expect(fakeWs.isConnected, isTrue);
    expect(fakeWs.sentEvents.any((e) => e['type'] == 'start_call'), isTrue);
  });

  test('stale STT callback from old session is discarded', () async {
    await controller.startCall();
    final currentSessionId = controller.state.activeSttSessionId;

    // Send callback with wrong/old session ID
    fakeSpeech.partialController.add(SttPartialResult(
      text: 'stale callback words',
      sttSessionId: currentSessionId - 1,
      sequence: 1,
    ));

    await pumpEventQueue();

    expect(controller.state.latestPartial, '');
    expect(fakeWs.sentEvents.any((e) => e['type'] == 'stt.partial'), isFalse);

    // Send callback with correct session ID
    fakeSpeech.partialController.add(SttPartialResult(
      text: 'valid speech words',
      sttSessionId: currentSessionId,
      sequence: 1,
    ));

    await pumpEventQueue();

    expect(controller.state.latestPartial, 'valid speech words');
    expect(fakeWs.sentEvents.any((e) => e['type'] == 'stt.partial'), isTrue);
  });

  test('turn.committed transitions to thinking and stops STT', () async {
    await controller.startCall();

    controller.handleSocketEvent({
      'type': 'turn.committed',
      'final_transcript': 'halo luna apa kabar',
    });

    expect(controller.state.callState, CallState.thinking);
    expect(controller.state.currentTranscript, 'halo luna apa kabar');
    expect(fakeSpeech.isListening, isFalse);
  });

  test('AI speaking state stops STT and plays audio', () async {
    await controller.startCall();

    await controller.enterAiSpeaking(1);

    expect(controller.state.callState, CallState.aiSpeaking);
    expect(controller.state.assistantTurnId, 1);
    expect(fakeSpeech.isListening, isFalse);
  });

  test('manual bargeIn stops audio and enters listening after guard', () async {
    await controller.startCall();
    await controller.enterAiSpeaking(1);

    await controller.bargeIn();

    // Guard delay completes, should be listening with incremented userTurnId
    expect(controller.state.callState, CallState.listening);
    expect(controller.state.userTurnId, 2);
    expect(fakeAudio.isPlaying, isFalse);
    expect(fakeWs.sentEvents.any((e) => e['type'] == 'assistant.interrupt'), isTrue);
    expect(fakeSpeech.isListening, isTrue);
  });

  test('double tap barge-in is idempotent', () async {
    await controller.startCall();
    await controller.enterAiSpeaking(1);

    // First tap
    final future1 = controller.bargeIn();
    // Second tap immediately while in interrupting
    final future2 = controller.bargeIn();

    await Future.wait([future1, future2]);

    expect(controller.state.callState, CallState.listening);
    expect(controller.state.userTurnId, 2); // Only incremented once!
  });

  test('barge-in during thinking cancels pending generation and returns to listening', () async {
    await controller.startCall();
    await controller.enterThinking();
    expect(controller.state.callState, CallState.thinking);

    await controller.bargeIn();

    expect(controller.state.callState, CallState.listening);
    expect(controller.state.userTurnId, 2);
    expect(fakeSpeech.isListening, isTrue);
  });

  test('handlePlaybackFinished automatically enters listening after guard delay', () async {
    await controller.startCall();
    await controller.enterAiSpeaking(1);

    await controller.handlePlaybackFinished(1);

    expect(controller.state.callState, CallState.listening);
    expect(controller.state.userTurnId, 2);
    expect(fakeSpeech.isListening, isTrue);
    expect(fakeWs.sentEvents.any((e) => e['type'] == 'playback.finished'), isTrue);
  });

  test('forceCommit sends user.force_commit and enters thinking', () async {
    await controller.startCall();

    await controller.forceCommit();

    expect(controller.state.callState, CallState.thinking);
    expect(fakeWs.sentEvents.any((e) => e['type'] == 'user.force_commit'), isTrue);
    expect(fakeSpeech.isListening, isFalse);
  });

  test('toggleMute toggles mute and pauses STT', () async {
    await controller.startCall();
    expect(controller.state.isMuted, isFalse);

    controller.toggleMute();
    expect(controller.state.isMuted, isTrue);
    expect(fakeSpeech.isListening, isFalse);

    controller.toggleMute();
    expect(controller.state.isMuted, isFalse);
    expect(fakeSpeech.isListening, isTrue);
  });

  test('push-to-talk mode press and release flow', () async {
    await controller.startCall();

    controller.setConversationMode(ConversationMode.pushToTalk);
    expect(controller.state.conversationMode, ConversationMode.pushToTalk);
    expect(fakeSpeech.isListening, isFalse);

    // Press down
    await controller.pushToTalkPress();
    expect(fakeSpeech.isListening, isTrue);

    // Release
    await controller.pushToTalkRelease();
    expect(controller.state.callState, CallState.thinking);
    expect(fakeWs.sentEvents.any((e) => e['type'] == 'user.force_commit'), isTrue);
  });
}
