import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:luna_mobile/core/config/app_config.dart';
import 'package:luna_mobile/screens/dass_assessment_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppConfig.useMockData = true;
  });

  testWidgets(
      'DASSAssessmentScreen only shows AI button for AI-answered items and animates accordion smoothly',
      (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: DASSAssessmentScreen(),
        ),
      ),
    );

    // Initial pump and wait for mock data to load
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Item 1 and Item 2 are present
    expect(find.textContaining('Item 1 •'), findsOneWidget);
    expect(find.textContaining('Item 2 •'), findsOneWidget);

    // In mock data, only 7 items (1, 3, 6, 9, 11, 13, 19) have AI answers.
    // Items without AI answer (e.g. Item 2, Item 4) must NOT show the AI button.
    final iconButtonFinder = find.byIcon(Icons.auto_awesome_rounded);
    expect(iconButtonFinder, findsNWidgets(7));

    // Before expanding, the accordion content is dismissed and not in the tree
    expect(find.text('Tingkat Keyakinan AI'), findsNothing);

    // Tap the first AI icon button (Item 1) to expand downwards
    await tester.tap(iconButtonFinder.first);
    await tester.pumpAndSettle();

    // Now the accordion is visible with AI details
    expect(find.text('Tingkat Keyakinan AI'), findsOneWidget);
    expect(find.text('Penalaran AI Luna:'), findsOneWidget);

    // Tap again to collapse
    await tester.tap(iconButtonFinder.first);
    await tester.pumpAndSettle();

    // After collapse, the accordion content is dismissed
    expect(find.text('Tingkat Keyakinan AI'), findsNothing);
  });

  testWidgets('Top bar has Generate AI button, no refresh button, and pull-to-refresh works',
      (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: DASSAssessmentScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Generate AI button is present in the top bar
    expect(find.byIcon(Icons.auto_awesome), findsOneWidget);

    // Old refresh button is NOT present in top bar
    expect(find.byIcon(Icons.refresh_rounded), findsNothing);

    // RefreshIndicator is present for pull-to-refresh
    expect(find.byType(RefreshIndicator), findsOneWidget);

    // Pull down to trigger refresh
    await tester.fling(find.byType(ListView).first, const Offset(0.0, 300.0), 1000.0);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // Screen remains properly loaded after pull-to-refresh
    expect(find.textContaining('Item 1 •'), findsOneWidget);
  });
}
