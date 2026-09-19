import '../../domain/entities/conversation_entity.dart';
import 'chat_message_model.dart';

class ConversationModel extends ConversationEntity {
  const ConversationModel({
    required super.id,
    required super.title,
    required super.date,
    required super.lastSessionTime,
    required super.moodTag,
    required super.moodEmoji,
    required super.summary,
    required super.messages,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    final rawMessages = (json['messages'] ?? json['transcripts']) as List? ?? [];
    return ConversationModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      lastSessionTime: json['last_session_time']?.toString() ?? json['lastSessionTime']?.toString() ?? '',
      moodTag: json['mood_tag']?.toString() ?? json['moodTag']?.toString() ?? '',
      moodEmoji: json['mood_emoji']?.toString() ?? json['moodEmoji']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      messages: rawMessages.map((m) => ChatMessageModel.fromJson(m)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'last_session_time': lastSessionTime,
      'mood_tag': moodTag,
      'mood_emoji': moodEmoji,
      'summary': summary,
      'messages': messages.map((m) => (m as ChatMessageModel).toJson()).toList(),
    };
  }
}
