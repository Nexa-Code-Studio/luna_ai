import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../domain/repositories/voice_call_repository.dart';
import '../../domain/entities/voice_session_entity.dart';
import '../../data/datasources/mock_voice_call_datasource.dart';
import '../../data/datasources/remote_voice_call_datasource.dart';
import '../../data/repositories/voice_call_repository_impl.dart';

final voiceCallRepositoryProvider = Provider<VoiceCallRepository>((ref) {
  if (AppConfig.useMockData) {
    return VoiceCallRepositoryImpl(MockVoiceCallDataSource());
  } else {
    return VoiceCallRepositoryImpl(RemoteVoiceCallDataSource());
  }
});

final activeVoiceSessionProvider = StateProvider<VoiceSessionEntity?>((ref) => null);
