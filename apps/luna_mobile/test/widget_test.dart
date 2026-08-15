import 'package:flutter_test/flutter_test.dart';

import 'package:luna_mobile/main.dart';



void main() {

  testWidgets('LunaApp smoke test', (WidgetTester tester) async {

    await tester.pumpWidget(const LunaApp());

    expect(find.text('LUNA'), findsWidgets);

  });

}

