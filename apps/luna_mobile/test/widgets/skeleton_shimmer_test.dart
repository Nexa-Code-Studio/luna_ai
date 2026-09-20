import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luna_mobile/widgets/skeleton_shimmer.dart';

void main() {
  testWidgets('SkeletonShimmerHost renders child skeleton components correctly', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SkeletonShimmerHost(
            child: Column(
              children: [
                SkeletonBox(width: 100, height: 20),
                SkeletonLine(width: 150, height: 14),
                SkeletonCircle(size: 36),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byType(SkeletonShimmerHost), findsOneWidget);
    expect(find.byType(SkeletonBox), findsNWidgets(2)); // SkeletonLine internally uses SkeletonBox
    expect(find.byType(SkeletonLine), findsOneWidget);
    expect(find.byType(SkeletonCircle), findsOneWidget);

    // Pump forward by 500ms to test shimmer animation cycle without unbounded settle
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(SkeletonShimmerHost), findsOneWidget);
  });
}
