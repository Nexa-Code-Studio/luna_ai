class RiskWarningEntity {
  final bool detected;
  final String type;
  final String title;
  final String level;
  final String message;

  const RiskWarningEntity({
    required this.detected,
    required this.type,
    required this.title,
    required this.level,
    required this.message,
  });
}
