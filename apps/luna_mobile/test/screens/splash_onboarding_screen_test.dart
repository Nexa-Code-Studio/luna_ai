import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:luna_mobile/screens/splash_onboarding_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('SplashOnboardingScreen displays minimalist app icon splash and transitions to onboarding', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SplashOnboardingScreen(),
      ),
    );

    // Initial state: checking auth, should show minimalist splash branding
    expect(find.byKey(const ValueKey('minimalist_splash')), findsOneWidget);
    expect(find.text('LUNA'), findsOneWidget);
    expect(find.text('PENDAMPING KESEHATAN MENTAL'), findsOneWidget);

    // Pump to complete async auth check and fade animation (400ms)
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 400));

    // When no tokens exist, it should transition smoothly to onboarding welcome card
    expect(find.byKey(const ValueKey('onboarding_content')), findsOneWidget);
    expect(find.text('Selamat Datang di LUNA'), findsOneWidget);
    expect(find.text('Mulai Perjalananmu'), findsOneWidget);
  });
}
