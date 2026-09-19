import '../../domain/entities/risk_warning_entity.dart';

class RiskWarningModel extends RiskWarningEntity {
  const RiskWarningModel({
    required super.detected,
    required super.type,
    required super.title,
    required super.level,
    required super.message,
  });

  factory RiskWarningModel.fromJson(Map<String, dynamic> json) {
    return RiskWarningModel(
      detected: json['detected'] ?? false,
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      level: json['level']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'detected': detected,
      'type': type,
      'title': title,
      'level': level,
      'message': message,
    };
  }
}
