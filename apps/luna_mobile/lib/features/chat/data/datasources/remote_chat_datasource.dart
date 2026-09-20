import 'chat_datasource.dart';
import '../models/conversation_model.dart';
import '../models/chat_message_model.dart';
import '../../../../core/network/api_client.dart';

class RemoteChatDataSource implements ChatDataSource {
  final ApiClient _apiClient;

  RemoteChatDataSource({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  @override
  Future<List<ConversationModel>> getConversations() async {
    final response = await _apiClient.get('/conversations');
    final List<dynamic> list;
    if (response is Map && response['items'] is List) {
      list = response['items'] as List;
    } else if (response is List) {
      list = response;
    } else {
      list = [];
    }
    return list.map((e) => ConversationModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<ConversationModel?> getConversationById(String id) async {
    final response = await _apiClient.get('/conversations/$id');
    if (response == null) return null;
    return ConversationModel.fromJson(response);
  }

  @override
  Future<ChatMessageModel> sendMessage(String conversationId, String text) async {
    final response = await _apiClient.post('/conversations/$conversationId/messages', body: {
      'content': text,
      'modality': 'text',
    });
    return ChatMessageModel.fromJson(response);
  }
}
