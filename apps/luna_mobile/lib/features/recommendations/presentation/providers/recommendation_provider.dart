import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../domain/repositories/recommendation_repository.dart';
import '../../domain/entities/recommendation_entity.dart';
import '../../data/datasources/mock_recommendation_datasource.dart';
import '../../data/datasources/remote_recommendation_datasource.dart';
import '../../data/repositories/recommendation_repository_impl.dart';

final recommendationRepositoryProvider = Provider<RecommendationRepository>((ref) {
  if (AppConfig.useMockData) {
    return RecommendationRepositoryImpl(MockRecommendationDataSource());
  } else {
    return RecommendationRepositoryImpl(RemoteRecommendationDataSource());
  }
});

final recommendationsProvider = FutureProvider<List<RecommendationEntity>>((ref) async {
  final repo = ref.watch(recommendationRepositoryProvider);
  return repo.getRecommendations();
});
