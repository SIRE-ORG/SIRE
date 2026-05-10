import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class AuthSupabaseDatasource {
  Future<void> signInWithPassword({
    required String email,
    required String password,
  });
  Future<void> signInWithOtp({required String email});
  Future<void> updatePassword({required String password});
  Future<void> signOut();
  Future<void> resendVerification({required String email});
  String? getCurrentUserId();
  String? getCurrentJwt();
  Stream<AuthState> authStateChanges();
}
