import '../models/conversation_model.dart';
import '../models/chat_message_model.dart';

abstract class ChatDataSource {
  Future<List<ConversationModel>> getConversations();
  Future<ConversationModel?> getConversationById(String id);
  Future<ChatMessageModel> sendMessage(String conversationId, String text);
}
