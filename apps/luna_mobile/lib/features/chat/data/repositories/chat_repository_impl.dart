import '../../domain/repositories/chat_repository.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../datasources/chat_datasource.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatDataSource _dataSource;

  ChatRepositoryImpl(this._dataSource);

  @override
  Future<List<ConversationEntity>> getConversations() => _dataSource.getConversations();

  @override
  Future<ConversationEntity?> getConversationById(String id) => _dataSource.getConversationById(id);

  @override
  Future<ChatMessageEntity> sendMessage(String conversationId, String text) => _dataSource.sendMessage(conversationId, text);
}
