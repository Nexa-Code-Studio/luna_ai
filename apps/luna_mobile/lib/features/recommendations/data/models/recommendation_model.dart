import '../../domain/entities/recommendation_entity.dart';

class RecommendationModel extends RecommendationEntity {
  const RecommendationModel({
    required super.id,
    required super.title,
    required super.subtitle,
    required super.category,
    required super.iconName,
    required super.iconBgHex,
    super.isCompleted = false,
  });

  factory RecommendationModel.fromJson(Map<String, dynamic> json) {
    return RecommendationModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      category: json['category']?.toString() ?? 'general',
      iconName: json['icon_name']?.toString() ?? json['iconName']?.toString() ?? 'air',
      iconBgHex: json['icon_bg_hex']?.toString() ?? json['iconBgHex']?.toString() ?? '#8B93FF',
      isCompleted: json['is_completed'] ?? json['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'category': category,
      'icon_name': iconName,
      'icon_bg_hex': iconBgHex,
      'is_completed': isCompleted,
    };
  }

  RecommendationModel copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? category,
    String? iconName,
    String? iconBgHex,
    bool? isCompleted,
  }) {
    return RecommendationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      category: category ?? this.category,
      iconName: iconName ?? this.iconName,
      iconBgHex: iconBgHex ?? this.iconBgHex,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
