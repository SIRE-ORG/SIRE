import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/api_constants.dart';
import '../../../../core/network/app_exception.dart';
import '../models/auth_response_model.dart';
import '../models/user_profile_model.dart';
import 'auth_remote_datasource.dart';

/// Implementación real del datasource de auth contra el backend local.
///
/// Endpoints disponibles (backend en dev, authRoutes registrado en app.ts):
///   GET   /auth/me             → [getProfile]
///   PATCH /auth/account-status → [updateAccountStatus]
///
/// [registerGuest] sigue como error controlado: la ruta existe pero su
/// contrato difiere del documentado — espera el id de un usuario Supabase ya
/// creado (no lo crea, contra lo que dice api-contract.md) y responde
/// {data: profile} sin token ni userCreated. Hallazgo H3 en
/// claude/diseno_pruebas_calidad_hito3.md §8.3.
///
/// [updateProfile] sigue sin endpoint (PUT /users/me no existe).
///
/// Auth: el [AuthInterceptor] de [DioClient] inyecta x-user-id desde la
/// sesión Supabase; el backend identifica al usuario con ese header.
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

    final response = await dio.get(ApiConstants.authMe);
    final json =
        (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;

    return UserProfileModel.fromBackendProfile(
      json,
      // emailVerified no existe en el schema de Prisma; se deriva de Supabase.
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
      message:
          'POST /auth/register-guest difiere del contrato (requiere id de '
          'Supabase ya creado); flujo de invitado no integrable aún',
    );
  }

  @override
  Future<void> updateAccountStatus() async {
    final user = supabase.auth.currentUser;
    if (user == null) throw UnauthorizedException();

    await dio.patch(ApiConstants.authAccountStatus);
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
