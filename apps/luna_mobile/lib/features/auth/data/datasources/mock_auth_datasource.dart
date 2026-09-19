import 'auth_datasource.dart';
import '../models/user_model.dart';
import '../models/emergency_contact_model.dart';
import '../../../../core/storage/token_storage.dart';

class MockAuthDataSource implements AuthDataSource {
  UserModel? _currentUser = const UserModel(
    id: 'usr_001',
    name: 'Samsul',
    email: 'samsul@gmail.com',
    phone: '+62 812-3456-7890',
    bio: 'Pengguna aktif Luna AI.',
  );

  final List<EmergencyContactModel> _contacts = [
    const EmergencyContactModel(
      id: 'c1',
      name: 'Ibu (Siti Rahma)',
      relationship: 'Keluarga Utama',
      phone: '+62 812-9988-7766',
      isPrimary: true,
    ),
    const EmergencyContactModel(
      id: 'c2',
      name: 'Layanan Darurat Konseling 24/7',
      relationship: 'Hotline Kesehatan Mental',
      phone: '119 (Ext 8)',
      isPrimary: false,
    ),
    const EmergencyContactModel(
      id: 'c3',
      name: 'Dr. Anita, Sp.KJ',
      relationship: 'Psikiater Pendamping',
      phone: '+62 811-2233-4455',
      isPrimary: false,
    ),
  ];

  @override
  Future<UserModel?> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _currentUser;
  }

  @override
  Future<UserModel> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = UserModel(
      id: 'usr_001',
      name: email.split('@').first,
      email: email,
      phone: '+62 812-3456-7890',
    );
    await TokenStorage.saveToken('mock_jwt_token');
    return _currentUser!;
  }

  @override
  Future<UserModel> register(String name, String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = UserModel(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
    );
    await TokenStorage.saveToken('mock_jwt_token');
    return _currentUser!;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
    await TokenStorage.clearToken();
  }

  @override
  Future<List<EmergencyContactModel>> getEmergencyContacts() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_contacts);
  }

  @override
  Future<EmergencyContactModel> addEmergencyContact(EmergencyContactModel contact) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final newContact = contact.copyWith(id: 'c_${DateTime.now().millisecondsSinceEpoch}');
    _contacts.add(newContact);
    return newContact;
  }

  @override
  Future<void> deleteEmergencyContact(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _contacts.removeWhere((c) => c.id == id);
  }
}
