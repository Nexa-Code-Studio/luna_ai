import '../../domain/repositories/monitoring_repository.dart';
import '../../domain/entities/monitoring_data_entity.dart';
import '../datasources/monitoring_datasource.dart';

class MonitoringRepositoryImpl implements MonitoringRepository {
  final MonitoringDataSource _dataSource;

  MonitoringRepositoryImpl(this._dataSource);

  @override
  Future<MonitoringDataEntity> getMonitoringData(String periodKey) => _dataSource.getMonitoringData(periodKey);
}
