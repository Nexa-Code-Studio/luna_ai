import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../domain/repositories/monitoring_repository.dart';
import '../../domain/entities/monitoring_data_entity.dart';
import '../../data/datasources/mock_monitoring_datasource.dart';
import '../../data/datasources/remote_monitoring_datasource.dart';
import '../../data/repositories/monitoring_repository_impl.dart';

final monitoringRepositoryProvider = Provider<MonitoringRepository>((ref) {
  if (AppConfig.useMockData) {
    return MonitoringRepositoryImpl(MockMonitoringDataSource());
  } else {
    return MonitoringRepositoryImpl(RemoteMonitoringDataSource());
  }
});

final selectedPeriodProvider = StateProvider<String>((ref) => 'today');

final monitoringDataProvider = FutureProvider<MonitoringDataEntity>((ref) async {
  final repo = ref.watch(monitoringRepositoryProvider);
  final period = ref.watch(selectedPeriodProvider);
  return repo.getMonitoringData(period);
});
