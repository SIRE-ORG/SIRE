import '../entities/user_profile.dart';
import '../repositories/auth_repository.dart';

class GetProfileUseCase {
  const GetProfileUseCase(this._repository);

  final AuthRepository _repository;

  Future<UserProfile?> call() => _repository.getProfile();
}
