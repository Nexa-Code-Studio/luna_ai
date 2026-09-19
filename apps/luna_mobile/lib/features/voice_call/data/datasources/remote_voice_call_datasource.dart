import 'voice_call_datasource.dart';
import '../models/voice_session_model.dart';
import '../../../../core/network/api_client.dart';

class RemoteVoiceCallDataSource implements VoiceCallDataSource {
  final ApiClient _apiClient;

  RemoteVoiceCallDataSource({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  @override
  Future<VoiceSessionModel> startCall() async {
    final response = await _apiClient.post('/voice/calls/start');
    return VoiceSessionModel.fromJson(response);
  }

  @override
  Future<VoiceSessionModel> endCall(String sessionId, int durationSeconds) async {
    final response = await _apiClient.post('/voice/calls/$sessionId/end', body: {
      'duration_seconds': durationSeconds,
    });
    return VoiceSessionModel.fromJson(response);
  }

  @override
  Future<VoiceSessionModel?> getSessionSummary(String sessionId) async {
    final response = await _apiClient.get('/voice/calls/$sessionId/summary');
    if (response == null) return null;
    return VoiceSessionModel.fromJson(response);
  }
}
