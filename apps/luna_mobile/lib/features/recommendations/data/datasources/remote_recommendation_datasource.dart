import 'recommendation_datasource.dart';
import '../models/recommendation_model.dart';
import '../../../../core/network/api_client.dart';

class RemoteRecommendationDataSource implements RecommendationDataSource {
  final ApiClient _apiClient;

  RemoteRecommendationDataSource({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  @override
  Future<List<RecommendationModel>> getRecommendations() async {
    final response = await _apiClient.get('/recommendations');
    final list = response as List? ?? [];
    return list.map((e) => RecommendationModel.fromJson(e)).toList();
  }

  @override
  Future<void> markAsCompleted(String id) async {
    await _apiClient.post('/recommendations/$id/complete');
  }
}
