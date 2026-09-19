import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/emergency_contact_entity.dart';
import '../../data/datasources/mock_auth_datasource.dart';
import '../../data/datasources/remote_auth_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (AppConfig.useMockData) {
    return AuthRepositoryImpl(MockAuthDataSource());
  } else {
    return AuthRepositoryImpl(RemoteAuthDataSource());
  }
});

final currentUserProvider = FutureProvider<UserEntity?>((ref) async {
  final repo = ref.watch(authRepositoryProvider);
  return repo.getCurrentUser();
});

final emergencyContactsProvider = FutureProvider<List<EmergencyContactEntity>>((ref) async {
  final repo = ref.watch(authRepositoryProvider);
  return repo.getEmergencyContacts();
});
