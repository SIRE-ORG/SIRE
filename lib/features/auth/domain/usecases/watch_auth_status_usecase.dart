import 'package:supabase_flutter/supabase_flutter.dart';

import '../repositories/auth_repository.dart';

class WatchAuthStatusUseCase {
  const WatchAuthStatusUseCase(this._repository);

  final AuthRepository _repository;

  Stream<AuthState> call() => _repository.authStateChanges();
}
