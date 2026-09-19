import 'monitoring_datasource.dart';
import '../models/monitoring_data_model.dart';
import '../../../../core/network/api_client.dart';

class RemoteMonitoringDataSource implements MonitoringDataSource {
  final ApiClient _apiClient;

  RemoteMonitoringDataSource({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  @override
  Future<MonitoringDataModel> getMonitoringData(String periodKey) async {
    final response = await _apiClient.get('/analytics/monitoring', queryParams: {'period': periodKey});
    return MonitoringDataModel.fromJson(response);
  }
}
