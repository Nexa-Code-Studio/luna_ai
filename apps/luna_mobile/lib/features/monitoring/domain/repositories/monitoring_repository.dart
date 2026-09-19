import '../entities/monitoring_data_entity.dart';

abstract class MonitoringRepository {
  Future<MonitoringDataEntity> getMonitoringData(String periodKey);
}
