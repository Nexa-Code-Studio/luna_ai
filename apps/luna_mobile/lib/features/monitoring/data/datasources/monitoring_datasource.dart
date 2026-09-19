import '../models/monitoring_data_model.dart';

abstract class MonitoringDataSource {
  Future<MonitoringDataModel> getMonitoringData(String periodKey);
}
