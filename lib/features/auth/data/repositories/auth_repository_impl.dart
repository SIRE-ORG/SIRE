import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/storage/local_storage_service.dart';
import '../../domain/entities/auth_result.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../datasources/auth_supabase_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required this.supabaseDatasource,
    required this.remoteDatasource,
    required this.storage,
  });

  final AuthSupabaseDatasource supabaseDatasource;
  final AuthRemoteDatasource remoteDatasource;
  final LocalStorageService storage;

  @override
  Future<void> login({required String email, required String password}) async {
    await supabaseDatasource.signInWithPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> sendMagicLink({required String email}) async {
    await supabaseDatasource.signInWithOtp(email: email);
  }

  @override
  Future<void> verifyOtp({required String email, required String token}) async {
    await supabaseDatasource.verifyOtp(email: email, token: token);
  }

  @override
  Future<void> signOut() async {
    await supabaseDatasource.signOut();
    await storage.delete(StorageKeys.token);
  }

  @override
  Future<AuthResult> registerGuest({
    required String name,
    required String email,
    required String phone,
  }) async {
    final response = await remoteDatasource.registerGuest(
      name: name,
      email: email,
      phone: phone,
    );
    if (response.token != null) {
      await storage.write(StorageKeys.token, response.token!);
    }
    return response.toEntity();
  }

  @override
  Future<void> activateAccount({required String password}) async {
    await supabaseDatasource.updatePassword(password: password);
    await remoteDatasource.updateAccountStatus();
  }

  @override
  Future<UserProfile?> getProfile() async {
    if (supabaseDatasource.getCurrentUserId() == null) return null;
    final model = await remoteDatasource.getProfile();
    return model.toEntity();
  }

  @override
  Future<UserProfile> updateProfile({
    String? name,
    String? phone,
    String? avatarUrl,
  }) async {
    final model = await remoteDatasource.updateProfile(
      name: name,
      phone: phone,
      avatarUrl: avatarUrl,
    );
    return model.toEntity();
  }

  @override
  Stream<AuthState> authStateChanges() => supabaseDatasource.authStateChanges();
}
