import 'package:equatable/equatable.dart';

/// [anon] no existe en el backend ni en `fromJson` (la DB solo conoce
/// `guest`/`active`): es un estado derivado en Flutter para una sesión
/// Supabase anónima que todavía no tiene fila de perfil. Ver
/// `authStatusProvider`.
enum AccountStatus { guest, active, anon }

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
