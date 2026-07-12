import 'package:supabase_flutter/supabase_flutter.dart';

import '../entities/auth_result.dart';
import '../entities/user_profile.dart';

abstract interface class AuthRepository {
  Future<void> login({required String email, required String password});

  /// Crea (o reutiliza) una sesión anónima. Idempotente: si ya hay sesión
  /// activa (anónima o no), no hace nada.
  Future<void> signInAnonymously();
  Future<void> sendMagicLink({required String email});
  Future<void> verifyOtp({
    required String email,
    required String token,
    OtpType type = OtpType.email,
  });

  /// Adjunta [email] al usuario Supabase actual (típicamente una sesión
  /// anónima con perfil guest ya creado). Dispara el envío de un OTP de
  /// cambio de correo que debe validarse con [verifyOtp] (`type:
  /// OtpType.emailChange`) antes de poder llamar [activateAccount].
  Future<void> updateEmail({required String email});
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
