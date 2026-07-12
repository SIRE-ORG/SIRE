import '../repositories/auth_repository.dart';

/// Adjunta un correo al usuario Supabase actual (paso 1 de la activación de
/// un guest anónimo). Dispara el envío del OTP de cambio de correo; el
/// llamador debe seguir con [VerifyOtpUseCase] usando `OtpType.emailChange`.
class UpdateEmailUseCase {
  const UpdateEmailUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call({required String email}) =>
      _repository.updateEmail(email: email);
}
