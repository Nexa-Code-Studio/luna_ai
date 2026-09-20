import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:luna_mobile/core/routes/app_router.dart';
import 'package:luna_mobile/core/routes/app_route_transitions.dart';
import 'package:luna_mobile/widgets/staggered_entrance.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppRouter onGenerateRoute tests', () {
    test('Returns PageRouteBuilder for modal route /support_emergency', () {
      final route = AppRouter.onGenerateRoute(
        const RouteSettings(name: '/support_emergency'),
      );
      expect(route, isNotNull);
      expect(route, isA<PageRouteBuilder>());
      expect(route!.settings.name, '/support_emergency');
    });

    test('Returns PageRouteBuilder for detail route /dass', () {
      final route = AppRouter.onGenerateRoute(
        const RouteSettings(name: '/dass'),
      );
      expect(route, isNotNull);
      expect(route, isA<PageRouteBuilder>());
      expect(route!.settings.name, '/dass');
    });

    test('Returns PageRouteBuilder with arguments for /voice_session_detail', () {
      final route = AppRouter.onGenerateRoute(
        const RouteSettings(
          name: '/voice_session_detail',
          arguments: {'title': 'Test Sesi', 'duration': '05:00'},
        ),
      );
      expect(route, isNotNull);
      expect(route, isA<PageRouteBuilder>());
      expect(route!.settings.name, '/voice_session_detail');
    });

    test('Returns PageRouteBuilder with arguments for /diary_detail', () {
      final route = AppRouter.onGenerateRoute(
        const RouteSettings(
          name: '/diary_detail',
          arguments: {'title': 'Jurnal Harian', 'date': 'Hari ini'},
        ),
      );
      expect(route, isNotNull);
      expect(route, isA<PageRouteBuilder>());
      expect(route!.settings.name, '/diary_detail');
    });

    test('Returns null for unknown route to let MaterialApp handle it or 404', () {
      final route = AppRouter.onGenerateRoute(
        const RouteSettings(name: '/unknown_non_existent_route'),
      );
      expect(route, isNull);
    });
  });

  group('AppRouteTransitions builders', () {
    test('modalSlideUpRoute creates 320ms transition with correct settings', () {
      final route = AppRouteTransitions.modalSlideUpRoute(
        page: const SizedBox(),
        settings: const RouteSettings(name: '/modal_test'),
      ) as PageRouteBuilder;
      expect(route.transitionDuration, const Duration(milliseconds: 320));
      expect(route.reverseTransitionDuration, const Duration(milliseconds: 240));
      expect(route.settings.name, '/modal_test');
    });

    test('horizontalDetailRoute creates 300ms transition with correct settings', () {
      final route = AppRouteTransitions.horizontalDetailRoute(
        page: const SizedBox(),
        settings: const RouteSettings(name: '/detail_test'),
      ) as PageRouteBuilder;
      expect(route.transitionDuration, const Duration(milliseconds: 300));
      expect(route.reverseTransitionDuration, const Duration(milliseconds: 240));
      expect(route.settings.name, '/detail_test');
    });

    test('fadeThroughRoute creates 280ms transition with correct settings', () {
      final route = AppRouteTransitions.fadeThroughRoute(
        page: const SizedBox(),
        settings: const RouteSettings(name: '/fade_test'),
      ) as PageRouteBuilder;
      expect(route.transitionDuration, const Duration(milliseconds: 280));
      expect(route.reverseTransitionDuration, const Duration(milliseconds: 220));
      expect(route.settings.name, '/fade_test');
    });
  });

  group('StaggeredEntrance widget tests', () {
    testWidgets('Renders child widget immediately and animates', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StaggeredEntrance(
              index: 0,
              child: Text('Test Element 0'),
            ),
          ),
        ),
      );

      // Child is present in the widget tree
      expect(find.text('Test Element 0'), findsOneWidget);

      // Advance animation through delay and transition
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Test Element 0'), findsOneWidget);
    });

    testWidgets('Multiple StaggeredEntrance items with different indexes animate in sequence', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                StaggeredEntrance(index: 0, child: Text('Item 0')),
                StaggeredEntrance(index: 1, child: Text('Item 1')),
                StaggeredEntrance(index: 2, child: Text('Item 2')),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);

      // Pump through full duration
      await tester.pumpAndSettle();

      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
    });
  });
}
