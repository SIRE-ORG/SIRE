import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/api_constants.dart';
import '../../../../core/network/app_exception.dart';
import '../models/auth_response_model.dart';
import '../models/update_profile_request_model.dart';
import '../models/user_profile_model.dart';
import 'auth_remote_datasource.dart';

/// Implementación real del datasource de auth contra el backend local.
///
/// Endpoints disponibles (backend en dev, authRoutes/userRoutes registrados
/// en app.ts):
///   GET   /auth/me   -> [getProfile]
///   POST  /auth/register-guest  -> [registerGuest]
///   PATCH /auth/account-status  -> [updateAccountStatus]
///   PUT   /users/me  -> [updateProfile]
///
/// [registerGuest] fue destrabado (H3): el backend espera el id de un usuario
/// Supabase ya creado (no lo crea él) e inserta la fila profile con ese id.
/// Responde {data: profile} sin token ni userCreated; se construye el
/// AuthResponseModel a partir de data.profile.
///
/// [updateProfile] pega contra PUT /users/me (agregado en el backend). OJO:
/// el Render desplegado puede no tener aún el endpoint (404 del servidor
/// viejo) - eso se propaga como [NotFoundException] vía el interceptor de
/// errores de Dio y lo maneja con gracia quien llame a este método (ver
/// EditProfileScreen).
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
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw UnauthorizedException();

    // El backend exige el id de un usuario Supabase ya creado (H3) e inserta el
    // profile con ese id. Body: {id, email, name, phone}.
    final response = await dio.post(
      ApiConstants.authRegisterGuest,
      data: {'id': user.id, 'email': email, 'name': name, 'phone': phone},
    );
    final profile =
        (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return AuthResponseModel(
      userId: profile['id'] as String,
      accountStatus: (profile['accountStatus'] as String?) ?? 'guest',
      userCreated: true,
      token: null,
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
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw UnauthorizedException();

    final response = await dio.put(
      ApiConstants.usersMe,
      data: UpdateProfileRequestModel(
        name: name,
        phone: phone,
        avatarUrl: avatarUrl,
      ).toJson(),
    );
    final json =
        (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;

    return UserProfileModel.fromBackendProfile(
      json,
      // emailVerified no existe en el schema de Prisma; se deriva de Supabase.
      emailVerified: user.emailConfirmedAt != null,
    );
  }
}
