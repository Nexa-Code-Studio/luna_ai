import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../services/daily_progress_local_service.dart';

/// Notifier managing real-time reactive updates for the user's daily self-care progress.
class DailyProgressNotifier extends StateNotifier<DailyProgressData> {
  StreamSubscription<DailyProgressData>? _streamSub;

  DailyProgressNotifier() : super(DailyProgressData(date: DailyProgressLocalService.getTodayWibDate())) {
    _init();
  }

  void _init() {
    // 1. Listen to broadcast stream from local persistence service
    _streamSub = DailyProgressLocalService.progressStream.listen((data) {
      if (mounted) {
        state = data;
      }
    });

    // 2. Load cached progress immediately
    loadProgress();

    // 3. Background sync with backend
    syncWithServer();
  }

  /// Load today's progress from local SharedPreferences
  Future<void> loadProgress() async {
    final local = await DailyProgressLocalService.loadTodayProgress();
    if (mounted) {
      state = local;
    }
  }

  /// Record conversation check-in
  Future<void> recordConversationCheckin({bool hasConversation = true, DateTime? now}) async {
    final updated = await DailyProgressLocalService.recordConversationCheckin(
      hasConversation: hasConversation,
      now: now,
    );
    if (mounted) {
      state = updated;
    }
  }

  /// Record diary check-in
  Future<void> recordDiaryCheckin({bool hasDiary = true, DateTime? now}) async {
    final updated = await DailyProgressLocalService.recordDiaryCheckin(
      hasDiary: hasDiary,
      now: now,
    );
    if (mounted) {
      state = updated;
    }
  }

  /// Record activity completion
  Future<void> recordActivityCompletion(String activityId, bool isCompleted, {DateTime? now}) async {
    final updated = await DailyProgressLocalService.recordActivityCompletion(
      activityId,
      isCompleted,
      now: now,
    );
    if (mounted) {
      state = updated;
    }
  }

  /// Toggle activity completion
  Future<void> toggleActivityCompletion(String activityId, {DateTime? now}) async {
    final updated = await DailyProgressLocalService.toggleActivityCompletion(
      activityId,
      now: now,
    );
    if (mounted) {
      state = updated;
    }
  }

  /// Synchronize today's progress with remote backend
  Future<void> syncWithServer() async {
    if (AppConfig.useMockData) return;

    try {
      final headers = await AppConfig.getAuthHeaders();
      final results = await Future.wait([
        // 0: Conversations today
        http
            .get(Uri.parse('${AppConfig.baseUrl}/conversations/today'), headers: headers)
            .timeout(const Duration(seconds: 4))
            .catchError((_) => http.Response('{}', 500)),
        // 1: Diary today
        http
            .get(Uri.parse('${AppConfig.baseUrl}/diaries/today'), headers: headers)
            .timeout(const Duration(seconds: 4))
            .catchError((_) => http.Response('{}', 500)),
      ]);

      bool hasConv = state.hasConversation;
      bool hasDiary = state.hasDiary;

      final resConv = results[0];
      if (resConv.statusCode == 200) {
        final data = jsonDecode(resConv.body);
        if (data is Map<String, dynamic>) {
          final count = data['total'] ?? (data['items'] as List?)?.length ?? 0;
          if (count > 0) hasConv = true;
        }
      }

      final resDiary = results[1];
      if (resDiary.statusCode == 200) {
        final data = jsonDecode(resDiary.body);
        if (data is Map<String, dynamic> && data['id'] != null) {
          hasDiary = true;
        }
      }

      if (hasConv != state.hasConversation || hasDiary != state.hasDiary) {
        DailyProgressData updated = state;
        if (hasConv) {
          updated = await DailyProgressLocalService.recordConversationCheckin(hasConversation: true);
        }
        if (hasDiary) {
          updated = await DailyProgressLocalService.recordDiaryCheckin(hasDiary: true);
        }
        if (mounted) {
          state = updated;
        }
      }
    } catch (_) {
      // Graceful offline fallback
    }
  }

  /// Refresh progress from both local and server
  Future<void> refresh() async {
    await loadProgress();
    await syncWithServer();
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    super.dispose();
  }
}

/// Global Riverpod provider for daily self-care progress.
final dailyProgressProvider =
    StateNotifierProvider<DailyProgressNotifier, DailyProgressData>((ref) {
  return DailyProgressNotifier();
});
