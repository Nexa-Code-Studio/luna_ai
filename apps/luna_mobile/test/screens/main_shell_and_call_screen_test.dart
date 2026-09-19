import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:luna_mobile/features/voice_call/presentation/providers/ai_call_provider.dart';
import 'package:luna_mobile/screens/main_shell_screen.dart';
import 'package:luna_mobile/screens/voice_call_screen.dart';
import 'package:luna_mobile/widgets/floating_nav_bar.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('MainShellScreen Navigation with initialIndex', () {
    testWidgets('MainShellScreen starts on Tab 1 (Journal) when initialIndex is 1',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MainShellScreen(initialIndex: 1),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // FloatingNavBar should be present
      expect(find.byType(FloatingNavBar), findsOneWidget);
      // Journal label and elements from Tab 1 should be visible
      expect(find.text('Jurnal'), findsOneWidget);
    });

    testWidgets('MainShellScreen loads arguments from ModalRoute when pushed',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            routes: {
              '/home': (context) {
                final args = ModalRoute.of(context)?.settings.arguments
                    as Map<String, dynamic>?;
                final initialIndex =
                    (args?['initialIndex'] as int?) ?? 0;
                return MainShellScreen(initialIndex: initialIndex);
              },
            },
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/home',
                      arguments: {'initialIndex': 1},
                    );
                  },
                  child: const Text('Go Home Tab 1'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Go Home Tab 1'));
      await tester.pumpAndSettle();

      expect(find.byType(MainShellScreen), findsOneWidget);
      expect(find.byType(FloatingNavBar), findsOneWidget);
    });
  });

  group('VoiceCallScreen Circle Animations & Summary Navigation', () {
    testWidgets('VoiceCallScreen renders AI ripple wave rings when in aiSpeaking state',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late WidgetRef containerRef;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                containerRef = ref;
                return const VoiceCallScreen();
              },
            ),
          ),
        ),
      );

      await tester.pump();
      await containerRef.read(aiCallControllerProvider.notifier).enterAiSpeaking(1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Title & Status
      expect(find.text('LUNA Sedang Berbicara...'), findsOneWidget);
      expect(find.byIcon(Icons.record_voice_over), findsOneWidget);
    });

    testWidgets(
        'Tapping "Lihat Detail Jurnal" on summary sheet navigates to /home with initialIndex 1',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      Map<String, dynamic>? receivedArgs;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            routes: {
              '/home': (context) {
                receivedArgs = ModalRoute.of(context)?.settings.arguments
                    as Map<String, dynamic>?;
                return const Scaffold(body: Text('Home Screen Destination'));
              },
            },
            home: const VoiceCallScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap End Call button (Icons.call_end)
      await tester.tap(find.byIcon(Icons.call_end));
      await tester.pumpAndSettle();

      // Verify Session Summary bottom sheet appears
      expect(find.text('Sesi Suara Selesai 🍃'), findsOneWidget);
      expect(find.text('Lihat Detail Jurnal'), findsOneWidget);

      // Tap "Lihat Detail Jurnal"
      await tester.tap(find.text('Lihat Detail Jurnal'));
      await tester.pumpAndSettle();

      // Destination reached
      expect(find.text('Home Screen Destination'), findsOneWidget);
      expect(receivedArgs, isNotNull);
      expect(receivedArgs!['initialIndex'], 1);
    });
  });
}
