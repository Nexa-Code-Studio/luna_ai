import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/voice_call_ws_client.dart';
import '../../data/services/ai_audio_playback_service.dart';
import '../../data/services/speech_recognition_service.dart';
import '../controllers/ai_call_controller.dart';
import '../controllers/ai_call_state.dart';

final speechRecognitionServiceProvider =
    Provider.autoDispose<SpeechRecognitionService>((ref) {
  final service = SpeechRecognitionService();
  ref.onDispose(() => service.dispose());
  return service;
});

final aiAudioPlaybackServiceProvider =
    Provider.autoDispose<AiAudioPlaybackService>((ref) {
  final service = AiAudioPlaybackService();
  ref.onDispose(() => service.dispose());
  return service;
});

final voiceCallWsClientProvider = Provider.autoDispose<VoiceCallWsClient>((ref) {
  final client = VoiceCallWsClient();
  ref.onDispose(() => client.dispose());
  return client;
});

final aiCallControllerProvider =
    StateNotifierProvider.autoDispose<AiCallController, AiCallViewState>((ref) {
  final speech = ref.watch(speechRecognitionServiceProvider);
  final playback = ref.watch(aiAudioPlaybackServiceProvider);
  final ws = ref.watch(voiceCallWsClientProvider);

  return AiCallController(
    speechService: speech,
    audioPlaybackService: playback,
    wsClient: ws,
  );
});
