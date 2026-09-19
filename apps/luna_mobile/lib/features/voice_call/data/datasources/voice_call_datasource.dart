import '../models/voice_session_model.dart';

abstract class VoiceCallDataSource {
  Future<VoiceSessionModel> startCall();
  Future<VoiceSessionModel> endCall(String sessionId, int durationSeconds);
  Future<VoiceSessionModel?> getSessionSummary(String sessionId);
}
