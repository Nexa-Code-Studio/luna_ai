import '../../domain/entities/voice_session_entity.dart';

class VoiceSessionModel extends VoiceSessionEntity {
  const VoiceSessionModel({
    required super.sessionId,
    required super.status,
    required super.durationSeconds,
    super.summary,
  });

  factory VoiceSessionModel.fromJson(Map<String, dynamic> json) {
    return VoiceSessionModel(
      sessionId: json['session_id']?.toString() ?? json['sessionId']?.toString() ?? '',
      status: json['status']?.toString() ?? 'active',
      durationSeconds: json['duration_seconds'] ?? json['durationSeconds'] ?? 0,
      summary: json['summary']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'status': status,
      'duration_seconds': durationSeconds,
      'summary': summary,
    };
  }

  VoiceSessionModel copyWith({
    String? sessionId,
    String? status,
    int? durationSeconds,
    String? summary,
  }) {
    return VoiceSessionModel(
      sessionId: sessionId ?? this.sessionId,
      status: status ?? this.status,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      summary: summary ?? this.summary,
    );
  }
}
