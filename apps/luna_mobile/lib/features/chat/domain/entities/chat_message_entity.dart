class ChatMessageEntity {
  final String id;
  final String conversationId;
  final bool isUser;
  final String time;
  final String text;
  final String? emotionTag;
  final String? emotionEmoji;

  const ChatMessageEntity({
    required this.id,
    required this.conversationId,
    required this.isUser,
    required this.time,
    required this.text,
    this.emotionTag,
    this.emotionEmoji,
  });
}
