class DASSItemEntity {
  final int itemId;
  final String scale; // 'stress' | 'anxiety' | 'depression'
  final String questionText;
  final int score; // 0, 1, 2, 3
  final String? evidence;
  final double confidence;
  final bool isUserEdited;

  const DASSItemEntity({
    required this.itemId,
    required this.scale,
    required this.questionText,
    required this.score,
    this.evidence,
    required this.confidence,
    required this.isUserEdited,
  });

  DASSItemEntity copyWith({
    int? itemId,
    String? scale,
    String? questionText,
    int? score,
    String? evidence,
    double? confidence,
    bool? isUserEdited,
  }) {
    return DASSItemEntity(
      itemId: itemId ?? this.itemId,
      scale: scale ?? this.scale,
      questionText: questionText ?? this.questionText,
      score: score ?? this.score,
      evidence: evidence ?? this.evidence,
      confidence: confidence ?? this.confidence,
      isUserEdited: isUserEdited ?? this.isUserEdited,
    );
  }
}

class DASSAssessmentEntity {
  final String? id;
  final String userId;
  final String assessedDate;
  final int depressionScore;
  final int anxietyScore;
  final int stressScore;
  final String depressionSeverity;
  final String anxietySeverity;
  final String stressSeverity;
  final bool verifiedByUser;
  final String status;
  final List<DASSItemEntity> items;

  const DASSAssessmentEntity({
    this.id,
    required this.userId,
    required this.assessedDate,
    required this.depressionScore,
    required this.anxietyScore,
    required this.stressScore,
    required this.depressionSeverity,
    required this.anxietySeverity,
    required this.stressSeverity,
    required this.verifiedByUser,
    required this.status,
    required this.items,
  });

  DASSAssessmentEntity copyWith({
    String? id,
    String? userId,
    String? assessedDate,
    int? depressionScore,
    int? anxietyScore,
    int? stressScore,
    String? depressionSeverity,
    String? anxietySeverity,
    String? stressSeverity,
    bool? verifiedByUser,
    String? status,
    List<DASSItemEntity>? items,
  }) {
    return DASSAssessmentEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      assessedDate: assessedDate ?? this.assessedDate,
      depressionScore: depressionScore ?? this.depressionScore,
      anxietyScore: anxietyScore ?? this.anxietyScore,
      stressScore: stressScore ?? this.stressScore,
      depressionSeverity: depressionSeverity ?? this.depressionSeverity,
      anxietySeverity: anxietySeverity ?? this.anxietySeverity,
      stressSeverity: stressSeverity ?? this.stressSeverity,
      verifiedByUser: verifiedByUser ?? this.verifiedByUser,
      status: status ?? this.status,
      items: items ?? this.items,
    );
  }
}
