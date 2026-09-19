import '../models/user_model.dart';
import '../models/emergency_contact_model.dart';

abstract class AuthDataSource {
  Future<UserModel?> getCurrentUser();
  Future<UserModel> login(String email, String password);
  Future<UserModel> register(String name, String email, String password);
  Future<void> logout();
  Future<List<EmergencyContactModel>> getEmergencyContacts();
  Future<EmergencyContactModel> addEmergencyContact(EmergencyContactModel contact);
  Future<void> deleteEmergencyContact(String id);
}
