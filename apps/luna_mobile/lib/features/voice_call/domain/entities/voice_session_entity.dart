class VoiceSessionEntity {
  final String sessionId;
  final String status;
  final int durationSeconds;
  final String? summary;

  const VoiceSessionEntity({
    required this.sessionId,
    required this.status,
    required this.durationSeconds,
    this.summary,
  });
}
