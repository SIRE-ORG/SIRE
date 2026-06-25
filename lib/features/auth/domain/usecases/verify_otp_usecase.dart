import '../repositories/auth_repository.dart';

class VerifyOtpUseCase {
  const VerifyOtpUseCase(this._repo);

  final AuthRepository _repo;

  Future<void> call({required String email, required String token}) =>
      _repo.verifyOtp(email: email, token: token);
}
