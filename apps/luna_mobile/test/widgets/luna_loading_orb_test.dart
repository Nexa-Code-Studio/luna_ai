import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luna_mobile/widgets/luna_loading_orb.dart';

void main() {
  testWidgets('LunaLoadingOrb renders with halo and custom status message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LunaLoadingOrb(
            size: 200,
            message: 'Memuat ruang tenangmu...',
            showHalo: true,
          ),
        ),
      ),
    );

    expect(find.byType(LunaLoadingOrb), findsOneWidget);
    expect(find.text('Memuat ruang tenangmu...'), findsOneWidget);

    // Pump animated frames
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(LunaLoadingOrb), findsOneWidget);
  });
}
