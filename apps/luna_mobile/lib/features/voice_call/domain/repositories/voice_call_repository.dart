import '../entities/voice_session_entity.dart';

abstract class VoiceCallRepository {
  Future<VoiceSessionEntity> startCall();
  Future<VoiceSessionEntity> endCall(String sessionId, int durationSeconds);
  Future<VoiceSessionEntity?> getSessionSummary(String sessionId);
}
