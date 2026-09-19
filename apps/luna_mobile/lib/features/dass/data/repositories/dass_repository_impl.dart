import '../../domain/entities/dass_assessment_entity.dart';
import '../../domain/repositories/dass_repository.dart';
import '../datasources/dass_datasource.dart';

class DASSRepositoryImpl implements DASSRepository {
  final DASSDataSource _dataSource;

  DASSRepositoryImpl(this._dataSource);

  @override
  Future<DASSAssessmentEntity> getTodayAssessment() {
    return _dataSource.getTodayAssessment();
  }

  @override
  Future<DASSAssessmentEntity> updateAssessment(List<Map<String, dynamic>> items) {
    return _dataSource.updateAssessment(items);
  }
}
