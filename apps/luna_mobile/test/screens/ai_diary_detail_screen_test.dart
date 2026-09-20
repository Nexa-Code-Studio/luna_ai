import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:luna_mobile/screens/ai_diary_detail_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('AiDiaryDetailScreen in isSingleSession mode renders standalone session UI', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final sessionArgs = {
      'title': 'Curhat Mengatasi Beban Kerja',
      'date': 'Hari ini, 09:15 AM',
      'isSingleSession': true,
      'sessionCount': 1,
      'lastSessionTime': '09:15 AM',
      'moodTag': 'Tenang & Damai',
      'moodEmoji': '😌',
      'summary': 'Pengguna merasa jauh lebih tenang setelah berdiskusi mengenai prioritas kerja.',
      'aiInsight': 'Pengguna merasa jauh lebih tenang setelah berdiskusi mengenai prioritas kerja.',
      'importantEvents': ['Membahas prioritas pekerjaan'],
      'emotionalReflection': 'Stres menurun secara signifikan.',
      'sessions': [
        {
          'id': 'sess_1',
          'title': 'Curhat Mengatasi Beban Kerja',
          'time': '09:15 AM',
          'moodTag': 'Tenang & Damai',
          'moodEmoji': '😌',
          'emotionsBreakdown': [
            {'label': 'Tenang', 'emoji': '😌', 'percent': 0.85, 'color': '#4ECDC4'},
          ],
          'transcripts': [
            {
              'isUser': true,
              'time': '09:15 AM',
              'text': 'Halo Luna, aku merasa lelah dengan deadline pekerjaan.',
              'emotionTag': 'lelah (80%)',
              'emotionEmoji': '💥',
            },
            {
              'isUser': false,
              'time': '09:16 AM',
              'text': 'Aku mendengarkanmu. Mari kita urai bebanmu satu per satu.',
              'emotionTag': '',
              'emotionEmoji': '',
            },
          ],
        }
      ],
      'selectedSessionId': 'sess_1',
    };

    await tester.pumpWidget(
      MaterialApp(
        home: AiDiaryDetailScreen(journalData: sessionArgs),
      ),
    );

    await tester.pump();

    // 1. Header verification
    expect(find.text('Curhat Mengatasi Beban Kerja'), findsOneWidget);
    expect(find.text('Hari ini, 09:15 AM • Tenang & Damai'), findsOneWidget);
    expect(find.textContaining('Sesi Suara'), findsNothing);

    // 2. Wawasan AI transformed to Ringkasan Percakapan
    expect(find.text('RINGKASAN PERCAKAPAN'), findsOneWidget);
    expect(find.text('WAWASAN AI KUMULATIF'), findsNothing);
    expect(find.textContaining('Pengguna merasa jauh lebih tenang setelah berdiskusi'), findsOneWidget);

    // 3. Removed containers
    expect(find.text('PERISTIWA PENTING HARIAN'), findsNothing);
    expect(find.text('REFLEKSI EMOSIONAL HARIAN'), findsNothing);
    expect(find.text('PILIH SESI UNTUK PENGURAIAN SPESIFIK'), findsNothing);

    // 4. Transcript tiles: Time is hidden
    expect(find.text('09:15 AM'), findsNothing);
    expect(find.text('09:16 AM'), findsNothing);

    // Transcript message text is present
    expect(find.text('Halo Luna, aku merasa lelah dengan deadline pekerjaan.'), findsOneWidget);
    expect(find.text('Aku mendengarkanmu. Mari kita urai bebanmu satu per satu.'), findsOneWidget);
  });

  testWidgets('AiDiaryDetailScreen in normal diary mode retains cumulative sections', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final diaryArgs = {
      'title': 'Refleksi Harian LUNA',
      'date': 'Hari ini',
      'isSingleSession': false,
      'sessionCount': 2,
      'lastSessionTime': '09:15 AM',
      'moodTag': 'Tenang 🌿',
      'moodEmoji': '🌿',
      'summary': 'Kumulatif evaluasi hari ini.',
      'aiInsight': 'Evaluasi hari ini menunjukkan stabilitas.',
      'importantEvents': ['Sesi pagi', 'Sesi sore'],
      'emotionalReflection': 'Emosi stabil.',
      'sessions': [
        {
          'id': 's1',
          'title': 'Sesi Pagi',
          'time': '08:00 AM',
          'moodTag': 'Tenang',
          'moodEmoji': '😌',
          'transcripts': [
            {'isUser': true, 'time': '08:00 AM', 'text': 'Pagi Luna'}
          ],
        },
        {
          'id': 's2',
          'title': 'Sesi Sore',
          'time': '05:00 PM',
          'moodTag': 'Lega',
          'moodEmoji': '😃',
          'transcripts': [
            {'isUser': true, 'time': '05:00 PM', 'text': 'Sore Luna'}
          ],
        },
      ],
      'selectedSessionId': 'all',
    };

    await tester.pumpWidget(
      MaterialApp(
        home: AiDiaryDetailScreen(journalData: diaryArgs),
      ),
    );

    await tester.pump();

    // Cumulative sections are present
    expect(find.text('Hari ini • 2 Sesi Suara'), findsOneWidget);
    expect(find.text('WAWASAN AI KUMULATIF'), findsOneWidget);
    expect(find.text('PERISTIWA PENTING HARIAN'), findsOneWidget);
    expect(find.text('REFLEKSI EMOSIONAL HARIAN'), findsOneWidget);
    expect(find.text('PILIH SESI UNTUK PENGURAIAN SPESIFIK'), findsOneWidget);
  });

  testWidgets('AiDiaryDetailScreen in isSingleSession mode with null summary renders skeleton or generation trigger', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final sessionArgs = {
      'title': 'Sesi Baru Tanpa Ringkasan',
      'date': 'Hari ini, 10:00 AM',
      'isSingleSession': true,
      'sessionCount': 1,
      'lastSessionTime': '10:00 AM',
      'moodTag': 'Netral',
      'moodEmoji': '😐',
      'summary': null,
      'sessions': [],
    };

    await tester.pumpWidget(
      MaterialApp(
        home: AiDiaryDetailScreen(journalData: sessionArgs),
      ),
    );

    expect(find.text('RINGKASAN PERCAKAPAN'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 700));
  });
}

