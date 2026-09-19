import 'auth_datasource.dart';
import '../models/user_model.dart';
import '../models/emergency_contact_model.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/storage/token_storage.dart';

class RemoteAuthDataSource implements AuthDataSource {
  final ApiClient _apiClient;

  RemoteAuthDataSource({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  @override
  Future<UserModel?> getCurrentUser() async {
    final response = await _apiClient.get('/auth/me');
    if (response == null) return null;
    return UserModel.fromJson(response);
  }

  @override
  Future<UserModel> login(String email, String password) async {
    final response = await _apiClient.post('/auth/login', body: {
      'email': email,
      'password': password,
    });
    if (response['access_token'] != null) {
      final token = response['access_token'] as String;
      AppConfig.authToken = token;
      await TokenStorage.saveToken(token);
    }
    return UserModel.fromJson(response['user']);
  }

  @override
  Future<UserModel> register(String name, String email, String password) async {
    final response = await _apiClient.post('/auth/register', body: {
      'name': name,
      'email': email,
      'password': password,
    });
    if (response['access_token'] != null) {
      final token = response['access_token'] as String;
      AppConfig.authToken = token;
      await TokenStorage.saveToken(token);
    }
    return UserModel.fromJson(response['user']);
  }

  @override
  Future<void> logout() async {
    try {
      await _apiClient.post('/auth/logout');
    } catch (_) {}
    AppConfig.authToken = null;
    await TokenStorage.clearToken();
  }

  @override
  Future<List<EmergencyContactModel>> getEmergencyContacts() async {
    final response = await _apiClient.get('/users/emergency-contacts');
    final list = response as List? ?? [];
    return list.map((e) => EmergencyContactModel.fromJson(e)).toList();
  }

  @override
  Future<EmergencyContactModel> addEmergencyContact(EmergencyContactModel contact) async {
    final response = await _apiClient.post('/users/emergency-contacts', body: contact.toJson());
    return EmergencyContactModel.fromJson(response);
  }

  @override
  Future<void> deleteEmergencyContact(String id) async {
    await _apiClient.delete('/users/emergency-contacts/$id');
  }
}
