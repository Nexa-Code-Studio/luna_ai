import 'risk_warning_entity.dart';

class DiarySessionSummaryEntity {
  final String id;
  final String title;
  final String time;
  final String moodTag;
  final String moodEmoji;

  const DiarySessionSummaryEntity({
    required this.id,
    required this.title,
    required this.time,
    required this.moodTag,
    required this.moodEmoji,
  });
}

class DiaryEntryEntity {
  final String id;
  final String title;
  final String date;
  final int sessionCount;
  final String lastSessionTime;
  final String moodTag;
  final String moodEmoji;
  final String summary;
  final RiskWarningEntity? riskWarning;
  final String aiInsight;
  final List<String> importantEvents;
  final String emotionalReflection;
  final List<DiarySessionSummaryEntity> sessions;

  const DiaryEntryEntity({
    required this.id,
    required this.title,
    required this.date,
    required this.sessionCount,
    required this.lastSessionTime,
    required this.moodTag,
    required this.moodEmoji,
    required this.summary,
    this.riskWarning,
    required this.aiInsight,
    required this.importantEvents,
    required this.emotionalReflection,
    required this.sessions,
  });
}
