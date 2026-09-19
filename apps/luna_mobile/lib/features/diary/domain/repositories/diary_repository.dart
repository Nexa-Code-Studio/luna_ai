import '../entities/diary_entry_entity.dart';

abstract class DiaryRepository {
  Future<List<DiaryEntryEntity>> getDiaryEntries({String? moodFilter, String? searchQuery});
  Future<DiaryEntryEntity?> getDiaryEntryById(String id);
  Future<DiaryEntryEntity> createDiaryEntry(String content, String moodTag);
  Future<void> deleteDiaryEntry(String id);
}
