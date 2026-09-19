import '../../domain/entities/diary_entry_entity.dart';
import 'risk_warning_model.dart';

class DiarySessionSummaryModel extends DiarySessionSummaryEntity {
  const DiarySessionSummaryModel({
    required super.id,
    required super.title,
    required super.time,
    required super.moodTag,
    required super.moodEmoji,
  });

  factory DiarySessionSummaryModel.fromJson(Map<String, dynamic> json) {
    return DiarySessionSummaryModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      moodTag: json['moodTag']?.toString() ?? json['mood_tag']?.toString() ?? '',
      moodEmoji: json['moodEmoji']?.toString() ?? json['mood_emoji']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'time': time,
      'moodTag': moodTag,
      'moodEmoji': moodEmoji,
    };
  }
}

class DiaryEntryModel extends DiaryEntryEntity {
  const DiaryEntryModel({
    required super.id,
    required super.title,
    required super.date,
    required super.sessionCount,
    required super.lastSessionTime,
    required super.moodTag,
    required super.moodEmoji,
    required super.summary,
    super.riskWarning,
    required super.aiInsight,
    required super.importantEvents,
    required super.emotionalReflection,
    required super.sessions,
  });

  factory DiaryEntryModel.fromJson(Map<String, dynamic> json) {
    final rawRisk = json['riskWarning'] ?? json['risk_warning'];
    final List rawEvents = (json['importantEvents'] as List?) ?? (json['important_events'] as List?) ?? [];
    final List rawSessions = (json['sessions'] as List?) ?? [];

    return DiaryEntryModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      sessionCount: json['sessionCount'] ?? json['session_count'] ?? 1,
      lastSessionTime: json['lastSessionTime']?.toString() ?? json['last_session_time']?.toString() ?? '',
      moodTag: json['moodTag']?.toString() ?? json['mood_tag']?.toString() ?? '',
      moodEmoji: json['moodEmoji']?.toString() ?? json['mood_emoji']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      riskWarning: rawRisk != null ? RiskWarningModel.fromJson(Map<String, dynamic>.from(rawRisk as Map)) : null,
      aiInsight: json['aiInsight']?.toString() ?? json['ai_insight']?.toString() ?? '',
      importantEvents: rawEvents.map((e) => e.toString()).toList(),
      emotionalReflection: json['emotionalReflection']?.toString() ?? json['emotional_reflection']?.toString() ?? '',
      sessions: rawSessions.map((s) => DiarySessionSummaryModel.fromJson(Map<String, dynamic>.from(s as Map))).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'sessionCount': sessionCount,
      'lastSessionTime': lastSessionTime,
      'moodTag': moodTag,
      'moodEmoji': moodEmoji,
      'summary': summary,
      'riskWarning': riskWarning != null ? (riskWarning as RiskWarningModel).toJson() : null,
      'aiInsight': aiInsight,
      'importantEvents': importantEvents,
      'emotionalReflection': emotionalReflection,
      'sessions': sessions.map((s) => (s as DiarySessionSummaryModel).toJson()).toList(),
    };
  }
}
