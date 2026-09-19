class RiskIndicatorEntity {
  final String name;
  final String type;
  final double percent;
  final String levelLabel;
  final String colorHex;
  final String badgeBgHex;

  const RiskIndicatorEntity({
    required this.name,
    required this.type,
    required this.percent,
    required this.levelLabel,
    required this.colorHex,
    required this.badgeBgHex,
  });
}

class EmotionalCenterEntity {
  final String status;
  final int level;
  final String description;
  final String textColorHex;

  const EmotionalCenterEntity({
    required this.status,
    required this.level,
    required this.description,
    required this.textColorHex,
  });
}

class MonitoringDataEntity {
  final String periodKey; // 'today', 'week', 'month'
  final String periodLabel;
  final String summary;
  final EmotionalCenterEntity emotionalCenter;
  final List<RiskIndicatorEntity> risks;
  final List<String> xLabels;
  final List<List<double>> chartData;

  const MonitoringDataEntity({
    required this.periodKey,
    required this.periodLabel,
    required this.summary,
    required this.emotionalCenter,
    required this.risks,
    required this.xLabels,
    required this.chartData,
  });
}
