import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class AuthSupabaseDatasource {
  Future<void> signInWithPassword({
    required String email,
    required String password,
  });

  /// Crea (o reutiliza) una sesión anónima de Supabase. La app la usa como
  /// primer paso del flujo de 3 fases (ANON → GUEST → ACTIVE): "Comenzar" en
  /// welcome_screen ya deja al usuario con sesión, sin pedirle datos.
  Future<void> signInAnonymously();
  Future<void> signInWithOtp({required String email});

  /// [type] distingue el OTP de registro directo ([OtpType.email], el
  /// default) del OTP de activación de un guest anónimo que recién adjunta
  /// su correo ([OtpType.emailChange], vía [updateEmail]).
  Future<void> verifyOtp({
    required String email,
    required String token,
    OtpType type = OtpType.email,
  });

  /// Adjunta un correo a un usuario Supabase que aún no tiene uno (típico de
  /// una sesión anónima ya con perfil guest). Dispara el envío del OTP de
  /// cambio de correo; el llamador debe verificarlo con [verifyOtp] y
  /// `type: OtpType.emailChange`.
  Future<void> updateEmail({required String email});
  Future<void> updatePassword({required String password});
  Future<void> signOut();
  Future<void> resendVerification({required String email});
  String? getCurrentUserId();
  String? getCurrentJwt();
  Stream<AuthState> authStateChanges();
}
