import '../repositories/auth_repository.dart';

class SignInAnonymouslyUseCase {
  const SignInAnonymouslyUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call() => _repository.signInAnonymously();
}
