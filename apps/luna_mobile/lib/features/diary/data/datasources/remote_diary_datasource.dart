import 'diary_datasource.dart';
import '../models/diary_entry_model.dart';
import '../../../../core/network/api_client.dart';

class RemoteDiaryDataSource implements DiaryDataSource {
  final ApiClient _apiClient;

  RemoteDiaryDataSource({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  @override
  Future<List<DiaryEntryModel>> getDiaryEntries({String? moodFilter, String? searchQuery}) async {
    final queryParams = <String, String>{};
    if (moodFilter != null) queryParams['mood'] = moodFilter;
    if (searchQuery != null) queryParams['search'] = searchQuery;

    final response = await _apiClient.get('/diaries', queryParams: queryParams.isNotEmpty ? queryParams : null);
    final list = response as List? ?? [];
    return list.map((e) => DiaryEntryModel.fromJson(e)).toList();
  }

  @override
  Future<DiaryEntryModel?> getDiaryEntryById(String id) async {
    final response = await _apiClient.get('/diaries/$id');
    if (response == null) return null;
    return DiaryEntryModel.fromJson(response);
  }

  @override
  Future<DiaryEntryModel?> getTodayDiary() async {
    final response = await _apiClient.get('/diaries/today');
    if (response == null) return null;
    return DiaryEntryModel.fromJson(response);
  }

  @override
  Future<DiaryEntryModel?> generateTodayDiary() async {
    final response = await _apiClient.post('/diaries/generate');
    if (response == null) return null;
    return DiaryEntryModel.fromJson(response);
  }

  @override
  Future<DiaryEntryModel> createDiaryEntry(String content, String moodTag) async {
    final response = await _apiClient.post('/diaries', body: {
      'content': content,
      'mood_tag': moodTag,
    });
    return DiaryEntryModel.fromJson(response);
  }

  @override
  Future<void> deleteDiaryEntry(String id) async {
    await _apiClient.delete('/diaries/$id');
  }
}
