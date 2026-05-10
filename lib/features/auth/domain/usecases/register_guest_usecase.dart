import '../entities/auth_result.dart';
import '../repositories/auth_repository.dart';

class RegisterGuestUseCase {
  const RegisterGuestUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthResult> call({
    required String name,
    required String email,
    required String phone,
  }) => _repository.registerGuest(name: name, email: email, phone: phone);
}
