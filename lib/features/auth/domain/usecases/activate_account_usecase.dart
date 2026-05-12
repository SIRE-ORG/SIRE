import '../../../../core/network/app_exception.dart';
import '../repositories/auth_repository.dart';

class ActivateAccountUseCase {
  const ActivateAccountUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call({required String password}) {
    if (password.length < 8) {
      throw ValidationException(
        fields: {'password': 'La contraseña debe tener al menos 8 caracteres'},
      );
    }
    return _repository.activateAccount(password: password);
  }
}
