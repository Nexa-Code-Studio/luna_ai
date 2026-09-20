import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:luna_mobile/screens/splash_onboarding_screen.dart';
import 'package:luna_mobile/widgets/luna_loading_orb.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('SplashOnboardingScreen displays LunaLoadingOrb during auth checking', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SplashOnboardingScreen(),
      ),
    );

    // Initial state: checking auth, should show LunaLoadingOrb
    expect(find.byType(LunaLoadingOrb), findsOneWidget);
    expect(find.text('Memuat ruang tenangmu...'), findsOneWidget);

    // Pump to progress minimum duration timer (1500ms)
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump(const Duration(milliseconds: 700));

    // When no tokens exist, it should transition to onboarding welcome card
    expect(find.text('Selamat Datang di LUNA'), findsOneWidget);
    expect(find.text('Mulai Perjalananmu'), findsOneWidget);
  });
}
