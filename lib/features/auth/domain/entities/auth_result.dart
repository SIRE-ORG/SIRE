import 'package:equatable/equatable.dart';

import 'user_profile.dart';

class AuthResult extends Equatable {
  const AuthResult({
    required this.userId,
    required this.accountStatus,
    required this.userCreated,
  });

  final String userId;
  final AccountStatus accountStatus;
  final bool userCreated;

  @override
  List<Object?> get props => [userId, accountStatus, userCreated];
}
