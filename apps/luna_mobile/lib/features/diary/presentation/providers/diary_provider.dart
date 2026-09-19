import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../domain/repositories/diary_repository.dart';
import '../../domain/entities/diary_entry_entity.dart';
import '../../data/datasources/mock_diary_datasource.dart';
import '../../data/datasources/remote_diary_datasource.dart';
import '../../data/repositories/diary_repository_impl.dart';

final diaryRepositoryProvider = Provider<DiaryRepository>((ref) {
  if (AppConfig.useMockData) {
    return DiaryRepositoryImpl(MockDiaryDataSource());
  } else {
    return DiaryRepositoryImpl(RemoteDiaryDataSource());
  }
});

final selectedMoodFilterProvider = StateProvider<String>((ref) => 'Semua');
final searchQueryProvider = StateProvider<String>((ref) => '');

final diaryEntriesProvider = FutureProvider<List<DiaryEntryEntity>>((ref) async {
  final repo = ref.watch(diaryRepositoryProvider);
  final filter = ref.watch(selectedMoodFilterProvider);
  final search = ref.watch(searchQueryProvider);
  return repo.getDiaryEntries(moodFilter: filter, searchQuery: search);
});

final diaryDetailProvider = FutureProvider.family<DiaryEntryEntity?, String>((ref, id) async {
  final repo = ref.watch(diaryRepositoryProvider);
  return repo.getDiaryEntryById(id);
});
