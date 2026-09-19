import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/emergency_contact_entity.dart';
import '../datasources/auth_datasource.dart';
import '../models/emergency_contact_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthDataSource _dataSource;

  AuthRepositoryImpl(this._dataSource);

  @override
  Future<UserEntity?> getCurrentUser() => _dataSource.getCurrentUser();

  @override
  Future<UserEntity> login(String email, String password) => _dataSource.login(email, password);

  @override
  Future<UserEntity> register(String name, String email, String password) => _dataSource.register(name, email, password);

  @override
  Future<void> logout() => _dataSource.logout();

  @override
  Future<List<EmergencyContactEntity>> getEmergencyContacts() => _dataSource.getEmergencyContacts();

  @override
  Future<EmergencyContactEntity> addEmergencyContact(EmergencyContactEntity contact) {
    final model = EmergencyContactModel(
      id: contact.id,
      name: contact.name,
      relationship: contact.relationship,
      phone: contact.phone,
      isPrimary: contact.isPrimary,
    );
    return _dataSource.addEmergencyContact(model);
  }

  @override
  Future<void> deleteEmergencyContact(String id) => _dataSource.deleteEmergencyContact(id);
}
