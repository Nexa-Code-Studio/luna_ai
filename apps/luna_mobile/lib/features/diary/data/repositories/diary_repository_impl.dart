import '../../domain/repositories/diary_repository.dart';
import '../../domain/entities/diary_entry_entity.dart';
import '../datasources/diary_datasource.dart';

class DiaryRepositoryImpl implements DiaryRepository {
  final DiaryDataSource _dataSource;

  DiaryRepositoryImpl(this._dataSource);

  @override
  Future<List<DiaryEntryEntity>> getDiaryEntries({String? moodFilter, String? searchQuery}) =>
      _dataSource.getDiaryEntries(moodFilter: moodFilter, searchQuery: searchQuery);

  @override
  Future<DiaryEntryEntity?> getDiaryEntryById(String id) => _dataSource.getDiaryEntryById(id);

  @override
  Future<DiaryEntryEntity> createDiaryEntry(String content, String moodTag) =>
      _dataSource.createDiaryEntry(content, moodTag);

  @override
  Future<void> deleteDiaryEntry(String id) => _dataSource.deleteDiaryEntry(id);
}
