import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../data/datasources/mock_chat_datasource.dart';
import '../../data/datasources/remote_chat_datasource.dart';
import '../../data/repositories/chat_repository_impl.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  if (AppConfig.useMockData) {
    return ChatRepositoryImpl(MockChatDataSource());
  } else {
    return ChatRepositoryImpl(RemoteChatDataSource());
  }
});

final conversationsProvider = FutureProvider<List<ConversationEntity>>((ref) async {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.getConversations();
});

final conversationDetailProvider = FutureProvider.family<ConversationEntity?, String>((ref, id) async {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.getConversationById(id);
});
