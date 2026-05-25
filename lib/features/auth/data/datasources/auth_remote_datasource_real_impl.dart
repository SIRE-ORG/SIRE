import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/api_constants.dart';
import '../../../../core/network/app_exception.dart';
import '../models/auth_response_model.dart';
import '../models/user_profile_model.dart';
import 'auth_remote_datasource.dart';

/// Implementación real del datasource de auth contra el backend local.
///
/// LIMITACIÓN (backend v0): [getProfile] llama GET /users/profiles (todos los
/// perfiles) y filtra por email de sesión Supabase, porque [ApiConstants.usersMe]
/// (GET /auth/me) está implementado en auth.controller.ts pero NO registrado
/// en app.ts. Cuando Cristian agregue authRoutes a app.ts, reemplazar el body
/// de [getProfile] por la llamada directa a [ApiConstants.usersMe].
///
/// Los demás métodos lanzan [ServerException] ENDPOINT_NOT_AVAILABLE porque
/// authRoutes no está montado en app.ts (ver claude/comentarios_backend.txt C).
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
    // Implementado en auth.controller.ts pero authRoutes no está en app.ts.
    throw ServerException(
      code: 'ENDPOINT_NOT_AVAILABLE',
      message: 'POST /auth/register-guest no registrado en app.ts aún',
    );
  }

  @override
  Future<void> updateAccountStatus() {
    // Implementado en auth.controller.ts pero authRoutes no está en app.ts.
    throw ServerException(
      code: 'ENDPOINT_NOT_AVAILABLE',
      message: 'PATCH /auth/account-status no registrado en app.ts aún',
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
      message: 'PUT /users/me no implementado en el backend',
    );
  }
}
