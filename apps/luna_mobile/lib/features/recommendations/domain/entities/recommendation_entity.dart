class RecommendationEntity {
  final String id;
  final String title;
  final String subtitle;
  final String category;
  final String iconName;
  final String iconBgHex;
  final bool isCompleted;

  const RecommendationEntity({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.iconName,
    required this.iconBgHex,
    this.isCompleted = false,
  });
}
