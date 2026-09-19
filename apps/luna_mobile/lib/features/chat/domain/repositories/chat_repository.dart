import '../entities/chat_message_entity.dart';
import '../entities/conversation_entity.dart';

abstract class ChatRepository {
  Future<List<ConversationEntity>> getConversations();
  Future<ConversationEntity?> getConversationById(String id);
  Future<ChatMessageEntity> sendMessage(String conversationId, String text);
}
