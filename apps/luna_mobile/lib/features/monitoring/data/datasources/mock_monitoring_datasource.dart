import 'monitoring_datasource.dart';
import '../models/monitoring_data_model.dart';

class MockMonitoringDataSource implements MonitoringDataSource {
  final Map<String, MonitoringDataModel> _mockData = {
    'today': const MonitoringDataModel(
      periodKey: 'today',
      periodLabel: 'Hari Ini',
      summary: 'Evaluasi 3 sesi suara hari ini menunjukkan kecemasan di pagi hari yang mereda di sore hari setelah jeda istirahat.',
      emotionalCenter: EmotionalCenterModel(
        status: 'Cukup (Kecenderungan Membaik)',
        level: 3,
        description: 'Keseimbangan emosi mulai pulih di penghujung hari.',
        textColorHex: '#F57F17',
      ),
      risks: [
        RiskIndicatorModel(
          name: 'Risiko Stres',
          type: 'stress',
          percent: 0.70,
          levelLabel: 'Tinggi (70%)',
          colorHex: '#D32F2F',
          badgeBgHex: '#FFDCDD',
        ),
        RiskIndicatorModel(
          name: 'Risiko Anxiety',
          type: 'anxiety',
          percent: 0.65,
          levelLabel: 'Sedang-Tinggi (65%)',
          colorHex: '#E57373',
          badgeBgHex: '#FFEBEE',
        ),
        RiskIndicatorModel(
          name: 'Risiko Depresi',
          type: 'depresi',
          percent: 0.30,
          levelLabel: 'Rendah-Sedang (30%)',
          colorHex: '#489BB8',
          badgeBgHex: '#E0F4FB',
        ),
      ],
      xLabels: ['06:00', '09:00', '12:00', '15:00', '18:00', '21:00'],
      chartData: [
        [0.1, 0.2, 0.5, 0.1, 0.05, 0.03, 0.02],
        [0.05, 0.15, 0.60, 0.15, 0.03, 0.01, 0.01],
        [0.2, 0.4, 0.25, 0.1, 0.03, 0.01, 0.01],
        [0.35, 0.45, 0.15, 0.03, 0.01, 0.00, 0.01],
        [0.25, 0.35, 0.30, 0.08, 0.01, 0.00, 0.01],
        [0.30, 0.40, 0.20, 0.08, 0.01, 0.00, 0.01],
      ],
    ),
    'week': const MonitoringDataModel(
      periodKey: 'week',
      periodLabel: 'Minggu Ini',
      summary: 'Grafik mingguan menunjukkan penurunan tingkat kecemasan sebesar 15% dibandingkan minggu lalu.',
      emotionalCenter: EmotionalCenterModel(
        status: 'Baik & Stabil',
        level: 4,
        description: 'Tingkat kesadaran emosionalmu meningkat signifikan minggu ini.',
        textColorHex: '#2E7D32',
      ),
      risks: [
        RiskIndicatorModel(
          name: 'Risiko Stres',
          type: 'stress',
          percent: 0.45,
          levelLabel: 'Sedang (45%)',
          colorHex: '#FB8C00',
          badgeBgHex: '#FFF3E0',
        ),
        RiskIndicatorModel(
          name: 'Risiko Anxiety',
          type: 'anxiety',
          percent: 0.35,
          levelLabel: 'Rendah-Sedang (35%)',
          colorHex: '#489BB8',
          badgeBgHex: '#E0F4FB',
        ),
        RiskIndicatorModel(
          name: 'Risiko Depresi',
          type: 'depresi',
          percent: 0.20,
          levelLabel: 'Rendah (20%)',
          colorHex: '#4CAF50',
          badgeBgHex: '#E8F5E9',
        ),
      ],
      xLabels: ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'],
      chartData: [
        [0.3, 0.3, 0.2, 0.1, 0.05, 0.03, 0.02],
        [0.25, 0.35, 0.25, 0.1, 0.03, 0.01, 0.01],
        [0.2, 0.4, 0.3, 0.05, 0.03, 0.01, 0.01],
        [0.4, 0.4, 0.15, 0.03, 0.01, 0.00, 0.01],
        [0.5, 0.3, 0.15, 0.03, 0.01, 0.00, 0.01],
        [0.6, 0.3, 0.08, 0.01, 0.00, 0.00, 0.01],
        [0.55, 0.35, 0.08, 0.01, 0.00, 0.00, 0.01],
      ],
    ),
  };

  @override
  Future<MonitoringDataModel> getMonitoringData(String periodKey) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockData[periodKey] ?? _mockData['today']!;
  }
}
