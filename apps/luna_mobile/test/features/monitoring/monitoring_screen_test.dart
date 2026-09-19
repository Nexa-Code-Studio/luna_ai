import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luna_mobile/features/monitoring/data/models/monitoring_data_model.dart';
import 'package:luna_mobile/features/monitoring/domain/entities/monitoring_data_entity.dart';
import 'package:luna_mobile/features/monitoring/presentation/providers/monitoring_provider.dart';
import 'package:luna_mobile/screens/monitoring_screen.dart';

void main() {
  group('MonitoringDataModel Tests', () {
    test('Correctly parses JSON from backend API', () {
      final json = {
        'periodKey': 'today',
        'periodLabel': 'Hari Ini',
        'summary': 'Evaluasi hari ini menunjukkan stabilitas emosional.',
        'emotionalCenter': {
          'status': 'Baik & Stabil',
          'level': 4,
          'description': 'Resiliensi emosional prima.',
          'textColorHex': '#2E7D32',
        },
        'risks': [
          {
            'name': 'Stres',
            'type': 'stress',
            'percent': 0.35,
            'levelLabel': 'Rendah (35%)',
            'colorHex': '#4CAF50',
            'badgeBgHex': '#E8F5E9',
          }
        ],
        'xLabels': ['06:00', '09:00', '12:00', '15:00', '18:00', '21:00'],
        'chartData': [
          [0.1, 0.5, 0.2, 0.1, 0.05, 0.03, 0.02],
          [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
          [0.2, 0.4, 0.2, 0.1, 0.05, 0.03, 0.02],
          [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
          [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
          [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
        ],
      };

      final model = MonitoringDataModel.fromJson(json);
      expect(model.periodKey, 'today');
      expect(model.periodLabel, 'Hari Ini');
      expect(model.summary, contains('stabilitas'));
      expect(model.emotionalCenter.level, 4);
      expect(model.risks.length, 1);
      expect(model.risks.first.percent, 0.35);
      expect(model.xLabels.length, 6);
      expect(model.chartData.length, 6);
    });
  });

  group('MonitoringScreen Widget Tests', () {
    testWidgets('Renders MonitoringScreen with data from provider', (tester) async {
      const mockEntity = MonitoringDataEntity(
        periodKey: 'today',
        periodLabel: 'Hari Ini',
        summary: 'Ringkasan emosi hari ini terpantau tenang.',
        emotionalCenter: EmotionalCenterEntity(
          status: 'Baik & Stabil',
          level: 4,
          description: 'Keseimbangan terjaga dengan baik.',
          textColorHex: '#2E7D32',
        ),
        risks: [
          RiskIndicatorEntity(
            name: 'Stres',
            type: 'stress',
            percent: 0.40,
            levelLabel: 'Sedang (40%)',
            colorHex: '#FB8C00',
            badgeBgHex: '#FFF3E0',
          )
        ],
        xLabels: ['06:00', '09:00', '12:00', '15:00', '18:00', '21:00'],
        chartData: [
          [0.1, 0.5, 0.2, 0.1, 0.05, 0.03, 0.02],
          [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
          [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
          [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
          [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
          [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            monitoringDataProvider.overrideWith((ref) async => mockEntity),
          ],
          child: const MaterialApp(
            home: MonitoringScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check Header & Titles
      expect(find.text('Ritem & Tren Emosional'), findsOneWidget);
      expect(find.text('RINGKASAN AI'), findsOneWidget);
      expect(find.text('Ringkasan emosi hari ini terpantau tenang.'), findsOneWidget);
      expect(find.text('STACKED BAR RITEM 7 EMOSI'), findsOneWidget);
      expect(find.text('TINGKAT RISIKO KESEHATAN MENTAL'), findsOneWidget);
      expect(find.text('Stres'), findsOneWidget);
      expect(find.text('Sedang (40%)'), findsOneWidget);
      expect(find.text('PUSAT EMOSIONAL'), findsOneWidget);
      expect(find.text('Baik & Stabil'), findsOneWidget);

      // Check Period Chips
      expect(find.text('Hari Ini'), findsWidgets);
      expect(find.text('Minggu Ini'), findsOneWidget);
      expect(find.text('Bulan Ini'), findsOneWidget);
    });

    testWidgets('Tapping period chip updates selectedPeriodProvider', (tester) async {
      late WidgetRef capturedRef;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            monitoringDataProvider.overrideWith((ref) async {
              final period = ref.watch(selectedPeriodProvider);
              return MonitoringDataEntity(
                periodKey: period,
                periodLabel: period == 'week' ? 'Minggu Ini' : 'Hari Ini',
                summary: 'Summary for $period',
                emotionalCenter: const EmotionalCenterEntity(
                  status: 'Stabil',
                  level: 3,
                  description: 'Normal',
                  textColorHex: '#F57F17',
                ),
                risks: const [],
                xLabels: const ['A', 'B'],
                chartData: const [
                  [0.5, 0.5, 0.0, 0.0, 0.0, 0.0, 0.0],
                  [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
                ],
              );
            }),
          ],
          child: Consumer(
            builder: (context, ref, child) {
              capturedRef = ref;
              return const MaterialApp(
                home: MonitoringScreen(),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(capturedRef.read(selectedPeriodProvider), 'today');

      // Tap 'Minggu Ini'
      await tester.tap(find.text('Minggu Ini'));
      await tester.pumpAndSettle();

      expect(capturedRef.read(selectedPeriodProvider), 'week');
      expect(find.text('Summary for week'), findsOneWidget);
    });
  });
}
