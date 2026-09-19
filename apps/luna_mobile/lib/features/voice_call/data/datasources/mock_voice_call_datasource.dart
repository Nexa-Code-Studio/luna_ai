import 'voice_call_datasource.dart';
import '../models/voice_session_model.dart';

class MockVoiceCallDataSource implements VoiceCallDataSource {
  VoiceSessionModel? _activeSession;

  @override
  Future<VoiceSessionModel> startCall() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _activeSession = VoiceSessionModel(
      sessionId: 'call_${DateTime.now().millisecondsSinceEpoch}',
      status: 'active',
      durationSeconds: 0,
    );
    return _activeSession!;
  }

  @override
  Future<VoiceSessionModel> endCall(String sessionId, int durationSeconds) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final summaryText = 'Ringkasan Sesi Telepon (${(durationSeconds ~/ 60)}m ${durationSeconds % 60}s):\n'
        '• Percakapan berlangsung hangat mengenai pengelolaan kecemasan.\n'
        '• LUNA memberikan panduan pernapasan dan saran istirahat singkat.\n'
        '• Mood pengguna berangsur tenang.';

    final ended = VoiceSessionModel(
      sessionId: sessionId,
      status: 'ended',
      durationSeconds: durationSeconds,
      summary: summaryText,
    );
    _activeSession = ended;
    return ended;
  }

  @override
  Future<VoiceSessionModel?> getSessionSummary(String sessionId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _activeSession;
  }
}
