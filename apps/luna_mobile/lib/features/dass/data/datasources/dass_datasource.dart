import '../../../../core/network/api_client.dart';
import '../models/dass_assessment_model.dart';

abstract class DASSDataSource {
  Future<DASSAssessmentModel> getTodayAssessment();
  Future<DASSAssessmentModel> updateAssessment(List<Map<String, dynamic>> items);
  Future<DASSAssessmentModel> extractTodayAssessment();
}

class RemoteDASSDataSource implements DASSDataSource {
  final ApiClient _apiClient;

  RemoteDASSDataSource({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  @override
  Future<DASSAssessmentModel> getTodayAssessment() async {
    final response = await _apiClient.get('/dass/today');
    return DASSAssessmentModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<DASSAssessmentModel> updateAssessment(List<Map<String, dynamic>> items) async {
    final response = await _apiClient.put(
      '/dass/today',
      body: {'items': items},
    );
    return DASSAssessmentModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<DASSAssessmentModel> extractTodayAssessment() async {
    final response = await _apiClient.post('/dass/extract-today');
    return DASSAssessmentModel.fromJson(response as Map<String, dynamic>);
  }
}

class MockDASSDataSource implements DASSDataSource {
  DASSAssessmentModel _mockData = _generateInitialMock();

  static DASSAssessmentModel _generateInitialMock() {
    final defaultQuestions = [
      {'item_id': 1, 'scale': 'stress', 'text': 'Saya merasa sulit untuk beristirahat atau menenangkan diri', 'score': 2, 'evidence': 'User: "Dari kemarin kepalaku tegang banget"', 'conf': 0.85},
      {'item_id': 2, 'scale': 'anxiety', 'text': 'Saya menyadari mulut saya terasa kering', 'score': 0, 'evidence': null, 'conf': 0.0},
      {'item_id': 3, 'scale': 'depression', 'text': 'Saya sama sekali tidak dapat merasakan perasaan positif', 'score': 1, 'evidence': 'User: "Hari ini rasanya flat aja, nggak semangat"', 'conf': 0.70},
      {'item_id': 4, 'scale': 'anxiety', 'text': 'Saya mengalami kesulitan bernapas (napas cepat)', 'score': 0, 'evidence': null, 'conf': 0.0},
      {'item_id': 5, 'scale': 'depression', 'text': 'Saya merasa sulit berinisiatif untuk melakukan sesuatu', 'score': 1, 'evidence': null, 'conf': 0.0},
      {'item_id': 6, 'scale': 'stress', 'text': 'Saya cenderung bereaksi berlebihan terhadap suatu situasi', 'score': 2, 'evidence': 'User: "Aku gampang marah sama hal-hal kecil"', 'conf': 0.80},
      {'item_id': 7, 'scale': 'anxiety', 'text': 'Saya mengalami gemetar (misalnya pada kedua tangan)', 'score': 0, 'evidence': null, 'conf': 0.0},
      {'item_id': 8, 'scale': 'stress', 'text': 'Saya merasa menghabiskan banyak energi karena gugup', 'score': 1, 'evidence': null, 'conf': 0.0},
      {'item_id': 9, 'scale': 'anxiety', 'text': 'Saya khawatir situasi di mana saya mungkin panik', 'score': 1, 'evidence': 'User: "Takut banget pas harus presentasi"', 'conf': 0.75},
      {'item_id': 10, 'scale': 'depression', 'text': 'Saya merasa tidak ada lagi hal baik di masa depan', 'score': 0, 'evidence': null, 'conf': 0.0},
      {'item_id': 11, 'scale': 'stress', 'text': 'Saya mendapati diri saya mudah gelisah atau resah', 'score': 2, 'evidence': 'User: "Gelisah mikirin deadline tugas"', 'conf': 0.88},
      {'item_id': 12, 'scale': 'stress', 'text': 'Saya merasa sulit untuk rileks atau bersantai', 'score': 2, 'evidence': null, 'conf': 0.0},
      {'item_id': 13, 'scale': 'depression', 'text': 'Saya merasa sedih, murung, dan tertekan', 'score': 1, 'evidence': 'User: "Sedih aja bawaannya"', 'conf': 0.65},
      {'item_id': 14, 'scale': 'stress', 'text': 'Saya tidak sabar menghadapi hal yang menghambat', 'score': 1, 'evidence': null, 'conf': 0.0},
      {'item_id': 15, 'scale': 'anxiety', 'text': 'Saya merasa hampir panik', 'score': 0, 'evidence': null, 'conf': 0.0},
      {'item_id': 16, 'scale': 'depression', 'text': 'Saya merasa tidak mampu antusias terhadap hal apa pun', 'score': 1, 'evidence': null, 'conf': 0.0},
      {'item_id': 17, 'scale': 'depression', 'text': 'Saya merasa bahwa diri saya tidak berharga', 'score': 0, 'evidence': null, 'conf': 0.0},
      {'item_id': 18, 'scale': 'stress', 'text': 'Saya merasa mudah tersinggung atau sensitif', 'score': 1, 'evidence': null, 'conf': 0.0},
      {'item_id': 19, 'scale': 'anxiety', 'text': 'Saya menyadari detak jantung berdegup kencang', 'score': 1, 'evidence': 'User: "Deg-degan tiba-tiba"', 'conf': 0.72},
      {'item_id': 20, 'scale': 'anxiety', 'text': 'Saya merasa takut tanpa alasan yang jelas', 'score': 0, 'evidence': null, 'conf': 0.0},
      {'item_id': 21, 'scale': 'depression', 'text': 'Saya merasa bahwa hidup ini tidak berarti', 'score': 0, 'evidence': null, 'conf': 0.0},
    ];

    final items = defaultQuestions.map((q) {
      return DASSItemModel(
        itemId: q['item_id'] as int,
        scale: q['scale'] as String,
        questionText: q['text'] as String,
        score: q['score'] as int,
        evidence: q['evidence'] as String?,
        confidence: (q['conf'] as num).toDouble(),
        isUserEdited: false,
      );
    }).toList();

    return DASSAssessmentModel(
      id: 'mock-dass-today',
      userId: 'mock-user-123',
      assessedDate: 'Hari Ini',
      depressionScore: 8, // (1+1+1+1)*2
      anxietyScore: 4,    // (1+1)*2
      stressScore: 22,    // (2+2+1+2+2+1+1)*2 = 22 -> Moderate
      depressionSeverity: 'Normal',
      anxietySeverity: 'Normal',
      stressSeverity: 'Moderate',
      verifiedByUser: false,
      status: 'auto_extracted',
      items: items,
    );
  }

  @override
  Future<DASSAssessmentModel> getTodayAssessment() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockData;
  }

  @override
  Future<DASSAssessmentModel> updateAssessment(List<Map<String, dynamic>> items) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final currentItems = List<DASSItemModel>.from(_mockData.items);
    final map = {for (var it in items) it['item_id'] as int: it['score'] as int};

    final updatedItems = currentItems.map((it) {
      if (map.containsKey(it.itemId)) {
        return DASSItemModel(
          itemId: it.itemId,
          scale: it.scale,
          questionText: it.questionText,
          score: map[it.itemId]!,
          evidence: it.evidence,
          confidence: it.confidence,
          isUserEdited: true,
        );
      }
      return it;
    }).toList();

    int depRaw = 0, anxRaw = 0, strRaw = 0;
    for (var it in updatedItems) {
      if (it.scale == 'depression') depRaw += it.score;
      if (it.scale == 'anxiety') anxRaw += it.score;
      if (it.scale == 'stress') strRaw += it.score;
    }

    _mockData = DASSAssessmentModel(
      id: _mockData.id,
      userId: _mockData.userId,
      assessedDate: _mockData.assessedDate,
      depressionScore: depRaw * 2,
      anxietyScore: anxRaw * 2,
      stressScore: strRaw * 2,
      depressionSeverity: (depRaw * 2 >= 14) ? 'Moderate' : 'Normal',
      anxietySeverity: (anxRaw * 2 >= 10) ? 'Moderate' : 'Normal',
      stressSeverity: (strRaw * 2 >= 19) ? 'Moderate' : 'Normal',
      verifiedByUser: true,
      status: 'verified',
      items: updatedItems,
    );

    return _mockData;
  }

  @override
  Future<DASSAssessmentModel> extractTodayAssessment() async {
    return _mockData;
  }
}
