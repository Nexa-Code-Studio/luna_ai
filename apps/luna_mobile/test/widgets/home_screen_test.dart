import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:luna_mobile/screens/home_screen.dart';

void main() {
  testWidgets(
      'HomeScreen renders psychological header, AI insight, 3-pillar progress, and tailored recommendation',
      (tester) async {
    SharedPreferences.setMockInitialValues({});

    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    int navigatedTab = -1;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          routes: {
            '/chat': (context) => const Scaffold(body: Text('Chat Screen')),
            '/profile': (context) => const Scaffold(body: Text('Profile Screen')),
            '/diary': (context) => const Scaffold(body: Text('Diary Screen')),
            '/monitoring': (context) => const Scaffold(body: Text('Monitoring Screen')),
            '/recommendation': (context) => const Scaffold(body: Text('Recommendation Screen')),
          },
          home: HomeScreen(
            onNavigateTab: (tab) => navigatedTab = tab,
          ),
        ),
      ),
    );

    // Initial pump and wait for microtasks
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // 1. Brand Header
    expect(find.text('LUNA'), findsOneWidget);

    // 2. Greeting & Insight Card
    expect(find.textContaining('Halo, '), findsOneWidget);
    expect(find.text('CATATAN DARI LUNA'), findsOneWidget);

    // 3. Quick Action Shortcuts
    expect(find.text('Curhat ke LUNA'), findsOneWidget);
    expect(find.text('Jurnal Refleksi AI'), findsOneWidget);
    expect(find.text('Asesmen DASS-21'), findsOneWidget);

    // 4. 3-Pillar Daily Therapeutic Progress
    expect(find.text('Perawatan Diri'), findsOneWidget);
    expect(find.text('Sesi Curhat Bersama Luna'), findsOneWidget);
    expect(find.text('Refleksi Jurnal Harian'), findsOneWidget);
    expect(find.text('Latihan Relaksasi & Koping'), findsOneWidget);

    // 5. Clinically-Informed Recommendation Section
    expect(find.text('Aktivitas Pilihan Hari Ini'), findsOneWidget);
    expect(find.text('Fokus: Relaksasi & Perawatan Diri'), findsOneWidget);
    expect(find.text('Lihat Semua'), findsOneWidget);
    expect(find.text('Mulai Latihan'), findsOneWidget);
    expect(find.text('Tandai'), findsOneWidget);
    expect(find.text('Latihan Pernapasan 4-7-8'), findsOneWidget);
    expect(find.text('0/3 Selesai'), findsOneWidget);

    // 6. Test toggling recommendation completion
    await tester.tap(find.text('Tandai'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Verify progress updated (Pillar 3 now completed)
    expect(find.text('1/3 Selesai'), findsOneWidget);
    // Verify it automatically advances to the next incomplete recommendation
    expect(find.text('Teknik Grounding 5-4-3-2-1'), findsOneWidget);

    // 7. Test opening detail modal via 'Mulai Latihan'
    await tester.tap(find.text('Mulai Latihan'));
    await tester.pumpAndSettle();
    expect(find.text('Langkah-Langkah yang Perlu Dilakukan:'), findsOneWidget);

    // Close modal via modal button
    await tester.tap(find.descendant(
      of: find.byType(ElevatedButton),
      matching: find.text('Saya Sudah Melakukan Latihan Ini'),
    ));
    await tester.pumpAndSettle();

    // 8. Test Tab Navigation from Quick Action
    await tester.tap(find.text('Jurnal Refleksi AI'));
    expect(navigatedTab, 1);
  });
}

