import '../models/auth_response_model.dart';
import '../models/user_profile_model.dart';

abstract interface class AuthRemoteDatasource {
  Future<AuthResponseModel> registerGuest({
    required String name,
    required String email,
    required String phone,
  });
  Future<void> updateAccountStatus();
  Future<UserProfileModel> getProfile();
  Future<UserProfileModel> updateProfile({
    String? name,
    String? phone,
    String? avatarUrl,
  });
}
