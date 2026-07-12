import 'package:supabase_flutter/supabase_flutter.dart';

import '../repositories/auth_repository.dart';

class VerifyOtpUseCase {
  const VerifyOtpUseCase(this._repo);

  final AuthRepository _repo;

  /// [type] distingue el registro directo ([OtpType.email], el default) de
  /// la activación de un guest anónimo que recién adjuntó su correo
  /// ([OtpType.emailChange], vía [UpdateEmailUseCase]).
  Future<void> call({
    required String email,
    required String token,
    OtpType type = OtpType.email,
  }) => _repo.verifyOtp(email: email, token: token, type: type);
}
