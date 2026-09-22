import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Data model representing the user's daily self-care progress.
class DailyProgressData {
  final String date;
  final bool hasConversation;
  final bool hasDiary;
  final Set<String> completedActivityIds;

  const DailyProgressData({
    required this.date,
    this.hasConversation = false,
    this.hasDiary = false,
    this.completedActivityIds = const {},
  });

  int get completedPillarsCount {
    int count = 0;
    if (hasConversation) count++;
    if (hasDiary) count++;
    if (completedActivityIds.isNotEmpty) count++;
    return count;
  }

  bool isActivityCompleted(String activityId) {
    return completedActivityIds.contains(activityId);
  }

  DailyProgressData copyWith({
    String? date,
    bool? hasConversation,
    bool? hasDiary,
    Set<String>? completedActivityIds,
  }) {
    return DailyProgressData(
      date: date ?? this.date,
      hasConversation: hasConversation ?? this.hasConversation,
      hasDiary: hasDiary ?? this.hasDiary,
      completedActivityIds: completedActivityIds ?? this.completedActivityIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'has_conversation': hasConversation,
      'has_diary': hasDiary,
      'completed_activity_ids': completedActivityIds.toList(),
    };
  }

  factory DailyProgressData.fromJson(Map<String, dynamic> json) {
    return DailyProgressData(
      date: json['date']?.toString() ?? '',
      hasConversation: json['has_conversation'] == true,
      hasDiary: json['has_diary'] == true,
      completedActivityIds: (json['completed_activity_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toSet() ??
          {},
    );
  }
}

/// Service to handle local persistence for daily self-care progress.
/// Automatically resets every new day using date-scoped keys (WIB UTC+7).
class DailyProgressLocalService {
  static const String _keyPrefix = 'luna_daily_progress_';

  static final StreamController<DailyProgressData> _progressStreamController =
      StreamController<DailyProgressData>.broadcast();

  /// Stream of daily progress updates emitted whenever progress changes.
  static Stream<DailyProgressData> get progressStream =>
      _progressStreamController.stream;

  /// Returns current WIB date string in format 'YYYY-MM-DD'
  static String getTodayWibDate([DateTime? dateTime]) {
    final now = dateTime ?? DateTime.now().toUtc().add(const Duration(hours: 7));
    final year = now.year.toString().padLeft(4, '0');
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static String _getStorageKey(String dateStr) {
    return '$_keyPrefix$dateStr';
  }

  /// Load today's daily progress from local storage.
  /// If today is a new day, returns a fresh progress state.
  static Future<DailyProgressData> loadTodayProgress({DateTime? now}) async {
    final todayStr = getTodayWibDate(now);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_getStorageKey(todayStr));

    if (raw == null || raw.isEmpty) {
      final initial = DailyProgressData(date: todayStr);
      _progressStreamController.add(initial);
      return initial;
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final loaded = DailyProgressData.fromJson(decoded);
      _progressStreamController.add(loaded);
      return loaded;
    } catch (_) {
      final fallback = DailyProgressData(date: todayStr);
      _progressStreamController.add(fallback);
      return fallback;
    }
  }

  /// Save daily progress to local storage and broadcast to all listeners.
  static Future<void> saveProgress(DailyProgressData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _getStorageKey(data.date),
      jsonEncode(data.toJson()),
    );
    _progressStreamController.add(data);
  }

  /// Record conversation check-in for today.
  static Future<DailyProgressData> recordConversationCheckin({
    bool hasConversation = true,
    DateTime? now,
  }) async {
    final current = await loadTodayProgress(now: now);
    final updated = current.copyWith(hasConversation: hasConversation);
    await saveProgress(updated);
    return updated;
  }

  /// Record diary check-in for today.
  static Future<DailyProgressData> recordDiaryCheckin({
    bool hasDiary = true,
    DateTime? now,
  }) async {
    final current = await loadTodayProgress(now: now);
    final updated = current.copyWith(hasDiary: hasDiary);
    await saveProgress(updated);
    return updated;
  }

  /// Record completion status of an activity for today.
  static Future<DailyProgressData> recordActivityCompletion(
    String activityId,
    bool isCompleted, {
    DateTime? now,
  }) async {
    final current = await loadTodayProgress(now: now);
    final updatedIds = Set<String>.from(current.completedActivityIds);
    if (isCompleted) {
      updatedIds.add(activityId);
    } else {
      updatedIds.remove(activityId);
    }
    final updated = current.copyWith(completedActivityIds: updatedIds);
    await saveProgress(updated);
    return updated;
  }

  /// Toggle completion status of an activity for today.
  static Future<DailyProgressData> toggleActivityCompletion(
    String activityId, {
    DateTime? now,
  }) async {
    final current = await loadTodayProgress(now: now);
    final isDone = current.isActivityCompleted(activityId);
    return recordActivityCompletion(activityId, !isDone, now: now);
  }

  /// Check if a specific activity is completed today.
  static Future<bool> isActivityCompletedToday(
    String activityId, {
    DateTime? now,
  }) async {
    final current = await loadTodayProgress(now: now);
    return current.isActivityCompleted(activityId);
  }
}
