import '../../domain/entities/auth_result.dart';
import '../../domain/entities/user_profile.dart';

class AuthResponseModel {
  const AuthResponseModel({
    required this.userId,
    required this.accountStatus,
    required this.userCreated,
    this.token,
  });

  final String userId;
  final String accountStatus;
  final bool userCreated;
  final String? token;

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      userId: json['userId'] as String,
      accountStatus: json['accountStatus'] as String,
      userCreated: json['userCreated'] as bool,
      token: json['token'] as String?,
    );
  }

  AuthResult toEntity() {
    return AuthResult(
      userId: userId,
      accountStatus: accountStatus == 'active'
          ? AccountStatus.active
          : AccountStatus.guest,
      userCreated: userCreated,
    );
  }
}
