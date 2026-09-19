import '../../domain/repositories/voice_call_repository.dart';
import '../../domain/entities/voice_session_entity.dart';
import '../datasources/voice_call_datasource.dart';

class VoiceCallRepositoryImpl implements VoiceCallRepository {
  final VoiceCallDataSource _dataSource;

  VoiceCallRepositoryImpl(this._dataSource);

  @override
  Future<VoiceSessionEntity> startCall() => _dataSource.startCall();

  @override
  Future<VoiceSessionEntity> endCall(String sessionId, int durationSeconds) => _dataSource.endCall(sessionId, durationSeconds);

  @override
  Future<VoiceSessionEntity?> getSessionSummary(String sessionId) => _dataSource.getSessionSummary(sessionId);
}
