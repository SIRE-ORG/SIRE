import '../repositories/auth_repository.dart';

class SendMagicLinkUseCase {
  const SendMagicLinkUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call({required String email}) =>
      _repository.sendMagicLink(email: email);
}
