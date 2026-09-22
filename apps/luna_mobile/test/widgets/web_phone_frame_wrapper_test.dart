import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luna_mobile/widgets/web_phone_frame_wrapper.dart';

void main() {
  testWidgets('WebPhoneFrameWrapper renders child directly on narrow screen or non-web', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: WebPhoneFrameWrapper(
          child: Text('Inner Mobile Screen'),
        ),
      ),
    );

    expect(find.text('Inner Mobile Screen'), findsOneWidget);
  });
}
