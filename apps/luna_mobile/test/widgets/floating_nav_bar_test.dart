import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luna_mobile/widgets/floating_nav_bar.dart';

void main() {
  testWidgets('FloatingNavBar renders 4 navigation items and central FAB', (tester) async {
    int tappedIndex = -1;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FloatingNavBar(
            currentIndex: 0,
            onTap: (index) => tappedIndex = index,
          ),
        ),
      ),
    );

    // Verify nav labels
    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Jurnal'), findsOneWidget);
    expect(find.text('Tren'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome), findsOneWidget); // Center FAB

    // Verify AnimatedPositioned pill exists
    final pillFinder = find.byType(AnimatedPositioned);
    expect(pillFinder, findsOneWidget);

    final initialPill = tester.widget<AnimatedPositioned>(pillFinder);
    expect(initialPill.duration, const Duration(milliseconds: 300));
    expect(initialPill.curve, Curves.easeOutCubic);

    // Tap on Jurnal (Index 1)
    await tester.tap(find.text('Jurnal'));
    expect(tappedIndex, 1);

    // Tap on Tren (Index 2)
    await tester.tap(find.text('Tren'));
    expect(tappedIndex, 2);

    // Re-render with currentIndex: 3
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FloatingNavBar(
            currentIndex: 3,
            onTap: (index) => tappedIndex = index,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final pillBox = tester.getRect(find.byType(AnimatedPositioned));
    final iconBox = tester.getRect(find.byIcon(Icons.person));
    final textBox = tester.getRect(find.text('Profil'));
    
    // Verify vertical centering of item column inside sliding pill
    final pillCenterY = pillBox.center.dy;
    final contentCenterY = (iconBox.top + textBox.bottom) / 2;
    expect((pillCenterY - contentCenterY).abs(), lessThan(1.0));
  });

  testWidgets('FloatingNavBar moves sliding pill across slots smoothly', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 500,
            height: 100,
            child: FloatingNavBar(
              currentIndex: 0,
              onTap: (_) {},
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    final pill0 = tester.widget<AnimatedPositioned>(find.byType(AnimatedPositioned));
    final left0 = pill0.left!;

    // Re-render with index 1 (Slot 1)
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 500,
            height: 100,
            child: FloatingNavBar(
              currentIndex: 1,
              onTap: (_) {},
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    final pill1 = tester.widget<AnimatedPositioned>(find.byType(AnimatedPositioned));
    final left1 = pill1.left!;
    expect(left1, greaterThan(left0)); // Moved right

    // Re-render with index 2 (Tren -> Slot 3, skipping center FAB slot 2)
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 500,
            height: 100,
            child: FloatingNavBar(
              currentIndex: 2,
              onTap: (_) {},
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    final pill2 = tester.widget<AnimatedPositioned>(find.byType(AnimatedPositioned));
    final left2 = pill2.left!;
    expect(left2, greaterThan(left1));

    // Difference between slot 3 and slot 1 is 2 slots (skipping slot 2)
    final diff01 = left1 - left0;
    final diff12 = left2 - left1;
    expect((diff12 / diff01).round(), 2);
  });
}
