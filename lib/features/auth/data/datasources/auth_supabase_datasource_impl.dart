import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_supabase_datasource.dart';

class AuthSupabaseDatasourceImpl implements AuthSupabaseDatasource {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signInWithOtp({required String email}) async {
    await _client.auth.signInWithOtp(email: email);
  }

  @override
  Future<void> updatePassword({required String password}) async {
    await _client.auth.updateUser(UserAttributes(password: password));
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  Future<void> resendVerification({required String email}) async {
    await _client.auth.resend(type: OtpType.signup, email: email);
  }

  @override
  String? getCurrentUserId() => _client.auth.currentUser?.id;

  @override
  String? getCurrentJwt() => _client.auth.currentSession?.accessToken;

  @override
  Stream<AuthState> authStateChanges() => _client.auth.onAuthStateChange;
}
