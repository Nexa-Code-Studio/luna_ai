import '../models/diary_entry_model.dart';

abstract class DiaryDataSource {
  Future<List<DiaryEntryModel>> getDiaryEntries({String? moodFilter, String? searchQuery});
  Future<DiaryEntryModel?> getDiaryEntryById(String id);
  Future<DiaryEntryModel?> getTodayDiary();
  Future<DiaryEntryModel?> generateTodayDiary();
  Future<DiaryEntryModel> createDiaryEntry(String content, String moodTag);
  Future<void> deleteDiaryEntry(String id);
}
