import '../../domain/repositories/recommendation_repository.dart';
import '../../domain/entities/recommendation_entity.dart';
import '../datasources/recommendation_datasource.dart';

class RecommendationRepositoryImpl implements RecommendationRepository {
  final RecommendationDataSource _dataSource;

  RecommendationRepositoryImpl(this._dataSource);

  @override
  Future<List<RecommendationEntity>> getRecommendations() => _dataSource.getRecommendations();

  @override
  Future<void> markAsCompleted(String id) => _dataSource.markAsCompleted(id);
}
