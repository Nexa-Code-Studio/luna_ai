import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:luna_mobile/services/daily_progress_local_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DailyProgressLocalService', () {
    final day1 = DateTime.utc(2026, 9, 19, 5, 0, 0); // 12:00 WIB
    final day2 = DateTime.utc(2026, 9, 20, 5, 0, 0); // 12:00 WIB next day

    test('Initial progress on a new day is empty with 0 completed pillars', () async {
      final progress = await DailyProgressLocalService.loadTodayProgress(now: day1);
      expect(progress.date, '2026-09-19');
      expect(progress.hasConversation, false);
      expect(progress.hasDiary, false);
      expect(progress.completedActivityIds, isEmpty);
      expect(progress.completedPillarsCount, 0);
    });

    test('Recording conversation and diary checkins updates and persists state', () async {
      await DailyProgressLocalService.recordConversationCheckin(
        hasConversation: true,
        now: day1,
      );
      var progress = await DailyProgressLocalService.loadTodayProgress(now: day1);
      expect(progress.hasConversation, true);
      expect(progress.completedPillarsCount, 1);

      await DailyProgressLocalService.recordDiaryCheckin(
        hasDiary: true,
        now: day1,
      );
      progress = await DailyProgressLocalService.loadTodayProgress(now: day1);
      expect(progress.hasDiary, true);
      expect(progress.completedPillarsCount, 2);
    });

    test('Recording and toggling activity completion works correctly', () async {
      await DailyProgressLocalService.recordActivityCompletion('act-1', true, now: day1);
      var progress = await DailyProgressLocalService.loadTodayProgress(now: day1);
      expect(progress.isActivityCompleted('act-1'), true);
      expect(progress.isActivityCompleted('act-2'), false);
      expect(progress.completedPillarsCount, 1);

      // Toggle act-1 off
      await DailyProgressLocalService.toggleActivityCompletion('act-1', now: day1);
      progress = await DailyProgressLocalService.loadTodayProgress(now: day1);
      expect(progress.isActivityCompleted('act-1'), false);
      expect(progress.completedPillarsCount, 0);

      // Toggle act-1 on again
      await DailyProgressLocalService.toggleActivityCompletion('act-1', now: day1);
      progress = await DailyProgressLocalService.loadTodayProgress(now: day1);
      expect(progress.isActivityCompleted('act-1'), true);
      expect(progress.completedPillarsCount, 1);
    });

    test('Progress automatically resets when date advances to next day', () async {
      // Day 1: Complete all 3 pillars
      await DailyProgressLocalService.recordConversationCheckin(hasConversation: true, now: day1);
      await DailyProgressLocalService.recordDiaryCheckin(hasDiary: true, now: day1);
      await DailyProgressLocalService.recordActivityCompletion('act-1', true, now: day1);

      final day1Progress = await DailyProgressLocalService.loadTodayProgress(now: day1);
      expect(day1Progress.completedPillarsCount, 3);

      // Day 2 (new day): Should be completely clean / reset
      final day2Progress = await DailyProgressLocalService.loadTodayProgress(now: day2);
      expect(day2Progress.date, '2026-09-20');
      expect(day2Progress.hasConversation, false);
      expect(day2Progress.hasDiary, false);
      expect(day2Progress.completedActivityIds, isEmpty);
      expect(day2Progress.completedPillarsCount, 0);

      // Day 1 data is still intact if loaded explicitly
      final checkDay1 = await DailyProgressLocalService.loadTodayProgress(now: day1);
      expect(checkDay1.completedPillarsCount, 3);
    });
  });
}
