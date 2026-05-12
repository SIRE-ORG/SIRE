import 'package:supabase_flutter/supabase_flutter.dart';

import '../entities/auth_result.dart';
import '../entities/user_profile.dart';

abstract interface class AuthRepository {
  Future<void> login({required String email, required String password});
  Future<void> sendMagicLink({required String email});
  Future<void> signOut();
  Future<AuthResult> registerGuest({
    required String name,
    required String email,
    required String phone,
  });
  Future<void> activateAccount({required String password});
  Future<UserProfile?> getProfile();
  Future<UserProfile> updateProfile({
    String? name,
    String? phone,
    String? avatarUrl,
  });
  Stream<AuthState> authStateChanges();
}
