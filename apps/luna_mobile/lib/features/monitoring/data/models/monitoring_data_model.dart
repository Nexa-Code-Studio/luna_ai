import '../../domain/entities/monitoring_data_entity.dart';

class RiskIndicatorModel extends RiskIndicatorEntity {
  const RiskIndicatorModel({
    required super.name,
    required super.type,
    required super.percent,
    required super.levelLabel,
    required super.colorHex,
    required super.badgeBgHex,
  });

  factory RiskIndicatorModel.fromJson(Map<String, dynamic> json) {
    return RiskIndicatorModel(
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      percent: (json['percent'] as num?)?.toDouble() ?? 0.0,
      levelLabel: json['levelLabel']?.toString() ?? json['level_label']?.toString() ?? '',
      colorHex: json['colorHex']?.toString() ?? json['color_hex']?.toString() ?? '#D32F2F',
      badgeBgHex: json['badgeBgHex']?.toString() ?? json['badge_bg_hex']?.toString() ?? '#FFDCDD',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'percent': percent,
      'levelLabel': levelLabel,
      'colorHex': colorHex,
      'badgeBgHex': badgeBgHex,
    };
  }
}

class EmotionalCenterModel extends EmotionalCenterEntity {
  const EmotionalCenterModel({
    required super.status,
    required super.level,
    required super.description,
    required super.textColorHex,
  });

  factory EmotionalCenterModel.fromJson(Map<dynamic, dynamic> json) {
    return EmotionalCenterModel(
      status: json['status']?.toString() ?? '',
      level: (json['level'] as num?)?.toInt() ?? 3,
      description: json['description']?.toString() ?? '',
      textColorHex: json['textColorHex']?.toString() ?? json['text_color_hex']?.toString() ?? '#F57F17',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'level': level,
      'description': description,
      'textColorHex': textColorHex,
    };
  }
}

class MonitoringDataModel extends MonitoringDataEntity {
  const MonitoringDataModel({
    required super.periodKey,
    required super.periodLabel,
    required super.summary,
    required super.emotionalCenter,
    required super.risks,
    required super.xLabels,
    required super.chartData,
  });

  factory MonitoringDataModel.fromJson(Map<dynamic, dynamic> json) {
    final rawRisks = json['risks'] as List? ?? [];
    final rawXLabels = (json['xLabels'] ?? json['x_labels']) as List? ?? [];
    final rawChartData = (json['chartData'] ?? json['chart_data']) as List? ?? [];

    final rawCenter = json['emotionalCenter'] ?? json['emotional_center'];
    final centerMap = rawCenter is Map ? rawCenter : const {};

    return MonitoringDataModel(
      periodKey: json['periodKey']?.toString() ?? json['period_key']?.toString() ?? 'today',
      periodLabel: json['periodLabel']?.toString() ?? json['period_label']?.toString() ?? 'Hari Ini',
      summary: json['summary']?.toString() ?? '',
      emotionalCenter: EmotionalCenterModel.fromJson(centerMap),
      risks: rawRisks
          .whereType<Map>()
          .map((r) => RiskIndicatorModel.fromJson(Map<String, dynamic>.from(r)))
          .toList(),
      xLabels: rawXLabels.map((x) => x.toString()).toList(),
      chartData: rawChartData
          .map((row) => (row as List? ?? []).map((val) => (val as num).toDouble()).toList())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'periodKey': periodKey,
      'periodLabel': periodLabel,
      'summary': summary,
      'emotionalCenter': (emotionalCenter as EmotionalCenterModel).toJson(),
      'risks': risks.map((r) => (r as RiskIndicatorModel).toJson()).toList(),
      'xLabels': xLabels,
      'chartData': chartData,
    };
  }
}
