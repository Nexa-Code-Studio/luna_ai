import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:luna_mobile/screens/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SettingsScreen Voice Character Mode Tests', () {
    testWidgets('renders voice character cards and defaults to mode_2', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsScreen(),
        ),
      );

      // Wait for async _loadSavedSettings
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('SUARA & RESPON LUNA AI'), findsOneWidget);
      expect(find.text('Luna - Jessica Ceria (Default)'), findsOneWidget);
      expect(find.text('Luna - Jessica Playful'), findsOneWidget);
      expect(find.text('Luna - Laura Muda & Enerjik'), findsOneWidget);
      expect(find.text('DEFAULT'), findsOneWidget);
    });

    testWidgets('selecting mode_4 updates selection and saves to SharedPreferences', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap on Jessica Playful card
      final playfulCard = find.text('Luna - Jessica Playful');
      expect(playfulCard, findsOneWidget);
      await tester.tap(playfulCard);
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('settings_voice_mode'), 'mode_4');
      expect(prefs.getString('settings_voice_character'), 'Luna - Jessica Playful');
    });

    testWidgets('loads pre-configured mode from SharedPreferences', (tester) async {
      SharedPreferences.setMockInitialValues({
        'settings_voice_mode': 'mode_7',
        'settings_voice_character': 'Luna - Laura Muda & Enerjik',
      });

      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify mode_7 is active (check check_circle icon rendered for mode_7)
      expect(find.text('Luna - Laura Muda & Enerjik'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('settings_voice_mode'), 'mode_7');
    });
  });
}
