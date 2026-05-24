import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/api_constants.dart';
import '../../../../core/network/app_exception.dart';
import '../models/auth_response_model.dart';
import '../models/user_profile_model.dart';
import 'auth_remote_datasource.dart';

/// Implementación real del datasource de auth contra el backend local.
///
/// LIMITACIÓN TEMPORAL (backend v0): [getProfile] llama GET /users/profiles
/// (devuelve todos los perfiles) y filtra por el email de la sesión Supabase,
/// porque GET /users/me aún no existe en el backend. Cuando Cristian lo
/// implemente, reemplazar el body de [getProfile] por la llamada directa a
/// [ApiConstants.usersMe].
///
/// Los demás métodos lanzan [ServerException] con ENDPOINT_NOT_AVAILABLE
/// porque los endpoints correspondientes no están implementados en el backend.
class AuthRemoteDatasourceRealImpl implements AuthRemoteDatasource {
  const AuthRemoteDatasourceRealImpl({
    required this.dio,
    required this.supabase,
  });

  final Dio dio;
  final SupabaseClient supabase;

  @override
  Future<UserProfileModel> getProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) throw UnauthorizedException();

    final response = await dio.get(ApiConstants.usersProfiles);
    final list = (response.data as List).cast<Map<String, dynamic>>();

    late final Map<String, dynamic> match;
    try {
      match = list.firstWhere((p) => (p['email'] as String?) == user.email);
    } on StateError {
      throw NotFoundException(code: 'PROFILE_NOT_FOUND');
    }

    return UserProfileModel.fromBackendProfile(
      match,
      emailVerified: user.emailConfirmedAt != null,
    );
  }

  @override
  Future<AuthResponseModel> registerGuest({
    required String name,
    required String email,
    required String phone,
  }) {
    throw ServerException(
      code: 'ENDPOINT_NOT_AVAILABLE',
      message: 'POST /auth/register-guest no implementado aún en el backend',
    );
  }

  @override
  Future<void> updateAccountStatus() {
    throw ServerException(
      code: 'ENDPOINT_NOT_AVAILABLE',
      message: 'PATCH /auth/account-status no implementado aún en el backend',
    );
  }

  @override
  Future<UserProfileModel> updateProfile({
    String? name,
    String? phone,
    String? avatarUrl,
  }) {
    throw ServerException(
      code: 'ENDPOINT_NOT_AVAILABLE',
      message: 'PUT /users/me no implementado aún en el backend',
    );
  }
}
