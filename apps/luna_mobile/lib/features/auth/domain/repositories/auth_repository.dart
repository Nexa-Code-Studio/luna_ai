import '../entities/user_entity.dart';
import '../entities/emergency_contact_entity.dart';

abstract class AuthRepository {
  Future<UserEntity?> getCurrentUser();
  Future<UserEntity> login(String email, String password);
  Future<UserEntity> register(String name, String email, String password);
  Future<void> logout();
  Future<List<EmergencyContactEntity>> getEmergencyContacts();
  Future<EmergencyContactEntity> addEmergencyContact(EmergencyContactEntity contact);
  Future<void> deleteEmergencyContact(String id);
}
