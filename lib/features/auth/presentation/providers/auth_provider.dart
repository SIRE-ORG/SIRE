import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/api_flags.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/datasources/auth_remote_datasource_mock_impl.dart';
import '../../data/datasources/auth_remote_datasource_real_impl.dart';
import '../../data/datasources/auth_supabase_datasource.dart';
import '../../data/datasources/auth_supabase_datasource_impl.dart';
import '../../data/datasources/avatar_storage_datasource.dart';
import '../../data/datasources/avatar_storage_datasource_impl.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/auth_result.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/activate_account_usecase.dart';
import '../../domain/usecases/get_profile_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_guest_usecase.dart';
import '../../domain/usecases/send_magic_link_usecase.dart';
import '../../domain/usecases/sign_in_anonymously_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';
import '../../domain/usecases/update_email_usecase.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import '../../domain/usecases/verify_otp_usecase.dart';

part 'auth_provider.g.dart';

// ---------------------------------------------------------------------------
// Infraestructura
// ---------------------------------------------------------------------------

@riverpod
AuthSupabaseDatasource authSupabaseDatasource(Ref ref) =>
    AuthSupabaseDatasourceImpl();

@riverpod
AuthRemoteDatasource authRemoteDatasource(Ref ref) => ApiFlags.useMocks
    ? AuthRemoteDatasourceMockImpl()
    : AuthRemoteDatasourceRealImpl(
        dio: DioClient.createSync().dio,
        supabase: Supabase.instance.client,
      );

@riverpod
AvatarStorageDatasource avatarStorageDatasource(Ref ref) =>
    AvatarStorageDatasourceImpl();

@riverpod
AuthRepository authRepository(Ref ref) => AuthRepositoryImpl(
  supabaseDatasource: ref.watch(authSupabaseDatasourceProvider),
  remoteDatasource: ref.watch(authRemoteDatasourceProvider),
  storage: const LocalStorageService(),
);

// ---------------------------------------------------------------------------
// Estado de autenticación
// ---------------------------------------------------------------------------

@riverpod
Future<UserProfile?> currentProfile(Ref ref) {
  final repo = ref.watch(authRepositoryProvider);
  return GetProfileUseCase(repo).call();
}

@riverpod
Future<AccountStatus?> authStatus(Ref ref) async {
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile != null) return profile.accountStatus;

  // Perfil null puede significar "sin sesión" o "sesión anónima sin fila de
  // perfil todavía" (registerGuest 404 tratado como null en el repositorio).
  // Se distinguen consultando la sesión Supabase directamente.
  final hasSession =
      ref.watch(authSupabaseDatasourceProvider).getCurrentUserId() != null;
  return hasSession ? AccountStatus.anon : null;
}

// ---------------------------------------------------------------------------
// AuthNotifier
// ---------------------------------------------------------------------------

@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> login({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => LoginUseCase(
        ref.read(authRepositoryProvider),
      ).call(email: email, password: password),
    );
    await _refresh();
  }

  /// Fase 1 del flujo de 3 fases: "Comenzar" en welcome_screen deja al
  /// usuario con una sesión anónima de Supabase, sin pedirle datos.
  Future<void> startAnonymousSession() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => SignInAnonymouslyUseCase(ref.read(authRepositoryProvider)).call(),
    );
    await _refresh();
  }

  /// Paso 1 de la activación de un guest anónimo (fase 3): adjunta [email]
  /// al usuario Supabase, lo que dispara el envío del OTP de cambio de
  /// correo. El llamador debe seguir con `verifyOtp(type:
  /// OtpType.emailChange)` y luego `activateAccount`.
  Future<void> startActivation({required String email}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => UpdateEmailUseCase(
        ref.read(authRepositoryProvider),
      ).call(email: email),
    );
  }

  Future<void> sendMagicLink({required String email}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => SendMagicLinkUseCase(
        ref.read(authRepositoryProvider),
      ).call(email: email),
    );
  }

  Future<void> verifyOtp({
    required String email,
    required String token,
    OtpType type = OtpType.email,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => VerifyOtpUseCase(
        ref.read(authRepositoryProvider),
      ).call(email: email, token: token, type: type),
    );
    await _refresh();
  }

  Future<AuthResult> registerGuest({
    required String name,
    required String email,
    required String phone,
  }) async {
    state = const AsyncLoading();
    final result = await RegisterGuestUseCase(
      ref.read(authRepositoryProvider),
    ).call(name: name, email: email, phone: phone);
    state = const AsyncData(null);
    // F3: justo tras registerGuest, un refetch inmediato del perfil puede
    // ganarle al backend (fila de perfil aún no propagada) y volver null
    // (getProfile lo trata como 404 → anon). Sin mitigación, el usuario
    // recién registrado vería de nuevo el form de invitado.
    await _refresh(retryProfileOnNull: true);
    return result;
  }

  Future<void> activateAccount({required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ActivateAccountUseCase(
        ref.read(authRepositoryProvider),
      ).call(password: password),
    );
    // F3: misma carrera que en registerGuest, tras el PATCH de
    // account-status — pero solo si la activación ocurrió de verdad: si
    // falló (p. ej. validación de password, nunca llegó a tocar el
    // repositorio) no hay carrera que mitigar.
    await _refresh(retryProfileOnNull: !state.hasError);
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => SignOutUseCase(ref.read(authRepositoryProvider)).call(),
    );
    await _refresh();
  }

  Future<void> _refresh({bool retryProfileOnNull = false}) async {
    ref.invalidate(currentProfileProvider);
    ref.invalidate(authStatusProvider);

    if (!retryProfileOnNull) return;

    // Reintento único acotado (~400ms), no polling indefinido: si el perfil
    // sigue null pasado ese margen, se acepta como estado real (p. ej. un
    // guest que de verdad no tiene fila todavía por otra razón). Es una
    // mitigación best-effort: si el refetch mismo falla (red, etc.) no debe
    // tumbar un registerGuest/activateAccount que ya tuvo éxito.
    try {
      final profile = await ref.read(currentProfileProvider.future);
      if (profile == null) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
        ref.invalidate(currentProfileProvider);
        ref.invalidate(authStatusProvider);
      }
    } catch (_) {
      // Ignorado a propósito: ver comentario arriba.
    }
  }
}

// ---------------------------------------------------------------------------
// ProfileNotifier
// ---------------------------------------------------------------------------

@riverpod
class ProfileNotifier extends _$ProfileNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> updateProfile({
    required String userId,
    String? name,
    String? phone,
    Uint8List? avatarBytes,
    String? avatarExtension,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () =>
          UpdateProfileUseCase(
            repository: ref.read(authRepositoryProvider),
            avatarDatasource: ref.read(avatarStorageDatasourceProvider),
          ).call(
            userId: userId,
            name: name,
            phone: phone,
            avatarBytes: avatarBytes,
            avatarExtension: avatarExtension,
          ),
    );
    ref.invalidate(currentProfileProvider);
    ref.invalidate(authStatusProvider);
  }
}
