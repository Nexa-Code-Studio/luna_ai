import '../models/recommendation_model.dart';

abstract class RecommendationDataSource {
  Future<List<RecommendationModel>> getRecommendations();
  Future<void> markAsCompleted(String id);
}
