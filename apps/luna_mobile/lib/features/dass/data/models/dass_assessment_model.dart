import '../../domain/entities/dass_assessment_entity.dart';

class DASSItemModel extends DASSItemEntity {
  const DASSItemModel({
    required super.itemId,
    required super.scale,
    required super.questionText,
    required super.score,
    super.evidence,
    required super.confidence,
    required super.isUserEdited,
  });

  factory DASSItemModel.fromJson(Map<String, dynamic> json) {
    return DASSItemModel(
      itemId: json['item_id'] is int ? json['item_id'] : int.parse(json['item_id'].toString()),
      scale: json['scale']?.toString() ?? 'stress',
      questionText: json['question_text']?.toString() ?? '',
      score: json['score'] is int ? json['score'] : int.tryParse(json['score']?.toString() ?? '0') ?? 0,
      evidence: json['evidence']?.toString(),
      confidence: (json['confidence'] is num)
          ? (json['confidence'] as num).toDouble()
          : double.tryParse(json['confidence']?.toString() ?? '0.0') ?? 0.0,
      isUserEdited: json['is_user_edited'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      'scale': scale,
      'question_text': questionText,
      'score': score,
      'evidence': evidence,
      'confidence': confidence,
      'is_user_edited': isUserEdited,
    };
  }
}

class DASSAssessmentModel extends DASSAssessmentEntity {
  const DASSAssessmentModel({
    super.id,
    required super.userId,
    required super.assessedDate,
    required super.depressionScore,
    required super.anxietyScore,
    required super.stressScore,
    required super.depressionSeverity,
    required super.anxietySeverity,
    required super.stressSeverity,
    required super.verifiedByUser,
    required super.status,
    required super.items,
  });

  factory DASSAssessmentModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final itemsList = rawItems
        .map((it) => DASSItemModel.fromJson(it as Map<String, dynamic>))
        .toList();

    return DASSAssessmentModel(
      id: json['id']?.toString(),
      userId: json['user_id']?.toString() ?? '',
      assessedDate: json['assessed_date']?.toString() ?? '',
      depressionScore: json['depression_score'] is int
          ? json['depression_score']
          : int.tryParse(json['depression_score']?.toString() ?? '0') ?? 0,
      anxietyScore: json['anxiety_score'] is int
          ? json['anxiety_score']
          : int.tryParse(json['anxiety_score']?.toString() ?? '0') ?? 0,
      stressScore: json['stress_score'] is int
          ? json['stress_score']
          : int.tryParse(json['stress_score']?.toString() ?? '0') ?? 0,
      depressionSeverity: json['depression_severity']?.toString() ?? 'Normal',
      anxietySeverity: json['anxiety_severity']?.toString() ?? 'Normal',
      stressSeverity: json['stress_severity']?.toString() ?? 'Normal',
      verifiedByUser: json['verified_by_user'] == true,
      status: json['status']?.toString() ?? 'auto_extracted',
      items: itemsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'assessed_date': assessedDate,
      'depression_score': depressionScore,
      'anxiety_score': anxietyScore,
      'stress_score': stressScore,
      'depression_severity': depressionSeverity,
      'anxiety_severity': anxietySeverity,
      'stress_severity': stressSeverity,
      'verified_by_user': verifiedByUser,
      'status': status,
      'items': items.map((it) {
        if (it is DASSItemModel) return it.toJson();
        return {
          'item_id': it.itemId,
          'scale': it.scale,
          'question_text': it.questionText,
          'score': it.score,
          'evidence': it.evidence,
          'confidence': it.confidence,
          'is_user_edited': it.isUserEdited,
        };
      }).toList(),
    };
  }
}
