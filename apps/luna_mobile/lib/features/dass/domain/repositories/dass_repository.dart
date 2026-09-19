import '../entities/dass_assessment_entity.dart';

abstract class DASSRepository {
  Future<DASSAssessmentEntity> getTodayAssessment();
  Future<DASSAssessmentEntity> updateAssessment(List<Map<String, dynamic>> items);
  Future<DASSAssessmentEntity> extractTodayAssessment();
}
