import '../../domain/entities/user_profile.dart';

class UserProfileModel {
  const UserProfileModel({
    required this.userId,
    required this.name,
    required this.email,
    this.phone,
    required this.accountStatus,
    required this.emailVerified,
    this.avatarUrl,
    required this.createdAt,
  });

  final String userId;
  final String name;
  final String email;
  final String? phone;
  final String accountStatus;
  final bool emailVerified;
  final String? avatarUrl;
  final String createdAt;

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      userId: json['userId'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      accountStatus: json['accountStatus'] as String,
      emailVerified: json['emailVerified'] as bool,
      avatarUrl: json['avatarUrl'] as String?,
      createdAt: json['createdAt'] as String,
    );
  }

  UserProfile toEntity() {
    return UserProfile(
      id: userId,
      name: name,
      email: email,
      phone: phone,
      accountStatus: accountStatus == 'active'
          ? AccountStatus.active
          : AccountStatus.guest,
      emailVerified: emailVerified,
      avatarUrl: avatarUrl,
    );
  }
}
