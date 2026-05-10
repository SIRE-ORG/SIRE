import '../models/auth_response_model.dart';
import '../models/user_profile_model.dart';
import 'auth_remote_datasource.dart';

class AuthRemoteDatasourceMockImpl implements AuthRemoteDatasource {
  @override
  Future<AuthResponseModel> registerGuest({
    required String name,
    required String email,
    required String phone,
  }) async {
    return AuthResponseModel(
      userId: 'mock-user-id-123',
      accountStatus: 'guest',
      userCreated: true,
      token: 'mock-token-123',
    );
  }

  @override
  Future<void> updateAccountStatus() async {}

  @override
  Future<UserProfileModel> getProfile() async {
    return const UserProfileModel(
      userId: 'mock-user-id-123',
      name: 'Usuario Demo',
      email: 'demo@sire.cl',
      phone: '+56912345678',
      accountStatus: 'guest',
      emailVerified: true,
      avatarUrl: null,
      createdAt: '2026-05-10T00:00:00Z',
    );
  }

  @override
  Future<UserProfileModel> updateProfile({
    String? name,
    String? phone,
    String? avatarUrl,
  }) async {
    return UserProfileModel(
      userId: 'mock-user-id-123',
      name: name ?? 'Usuario Demo',
      email: 'demo@sire.cl',
      phone: phone ?? '+56912345678',
      accountStatus: 'guest',
      emailVerified: true,
      avatarUrl: avatarUrl,
      createdAt: '2026-05-10T00:00:00Z',
    );
  }
}
