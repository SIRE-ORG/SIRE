import 'package:equatable/equatable.dart';

enum AccountStatus { guest, active }

class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.accountStatus,
    required this.emailVerified,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String email;
  final String? phone;
  final AccountStatus accountStatus;
  final bool emailVerified;
  final String? avatarUrl;

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    phone,
    accountStatus,
    emailVerified,
    avatarUrl,
  ];
}
