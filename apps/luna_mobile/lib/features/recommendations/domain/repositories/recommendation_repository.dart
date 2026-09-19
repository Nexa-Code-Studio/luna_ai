import '../entities/recommendation_entity.dart';

abstract class RecommendationRepository {
  Future<List<RecommendationEntity>> getRecommendations();
  Future<void> markAsCompleted(String id);
}
