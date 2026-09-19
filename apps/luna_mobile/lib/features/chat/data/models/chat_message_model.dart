import '../../domain/entities/chat_message_entity.dart';

class ChatMessageModel extends ChatMessageEntity {
  const ChatMessageModel({
    required super.id,
    required super.conversationId,
    required super.isUser,
    required super.time,
    required super.text,
    super.emotionTag,
    super.emotionEmoji,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id']?.toString() ?? '',
      conversationId: json['conversation_id']?.toString() ?? json['conversationId']?.toString() ?? '',
      isUser: json['is_user'] ?? json['isUser'] ?? (json['sender_role'] == 'user'),
      time: json['time']?.toString() ?? json['timestamp']?.toString() ?? '',
      text: json['text']?.toString() ?? json['content']?.toString() ?? '',
      emotionTag: json['emotion_tag'] ?? json['emotionTag'],
      emotionEmoji: json['emotion_emoji'] ?? json['emotionEmoji'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'is_user': isUser,
      'time': time,
      'text': text,
      'emotion_tag': emotionTag,
      'emotion_emoji': emotionEmoji,
    };
  }

  ChatMessageModel copyWith({
    String? id,
    String? conversationId,
    bool? isUser,
    String? time,
    String? text,
    String? emotionTag,
    String? emotionEmoji,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      isUser: isUser ?? this.isUser,
      time: time ?? this.time,
      text: text ?? this.text,
      emotionTag: emotionTag ?? this.emotionTag,
      emotionEmoji: emotionEmoji ?? this.emotionEmoji,
    );
  }
}
