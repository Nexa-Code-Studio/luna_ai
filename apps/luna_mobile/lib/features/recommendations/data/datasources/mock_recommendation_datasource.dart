import 'recommendation_datasource.dart';
import '../models/recommendation_model.dart';

class MockRecommendationDataSource implements RecommendationDataSource {
  final List<RecommendationModel> _items = [
    const RecommendationModel(
      id: 'rec_1',
      title: 'Latihan Pernapasan',
      subtitle: 'Luangkan waktu sejenak untuk menenangkan diri. (3 menit)',
      category: 'breathing',
      iconName: 'air',
      iconBgHex: '#8B93FF',
    ),
    const RecommendationModel(
      id: 'rec_2',
      title: 'Pertanyaan Refleksi Harian',
      subtitle: 'Apa satu hal yang memberimu rasa nyaman hari ini?',
      category: 'reflection',
      iconName: 'edit_note',
      iconBgHex: '#C3B8FF',
    ),
    const RecommendationModel(
      id: 'rec_3',
      title: 'Perawatan Diri',
      subtitle: 'Jalan santai selama 10 menit.',
      category: 'self_care',
      iconName: 'directions_walk',
      iconBgHex: '#489BB8',
    ),
    const RecommendationModel(
      id: 'rec_4',
      title: 'Latihan Reframing Kognitif',
      subtitle: 'Melihat masalah dari sudut pandang yang lebih positif.',
      category: 'cognitive_reframing',
      iconName: 'psychology',
      iconBgHex: '#9EA3C0',
    ),
  ];

  @override
  Future<List<RecommendationModel>> getRecommendations() async {
    await Future.delayed(const Duration(milliseconds: 250));
    return List.unmodifiable(_items);
  }

  @override
  Future<void> markAsCompleted(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _items[idx] = _items[idx].copyWith(isCompleted: true);
    }
  }
}
