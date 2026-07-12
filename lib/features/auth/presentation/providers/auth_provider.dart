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
import '../../domain/usecases/sign_out_usecase.dart';
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
  return profile?.accountStatus;
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
    _refresh();
  }

  Future<void> sendMagicLink({required String email}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => SendMagicLinkUseCase(
        ref.read(authRepositoryProvider),
      ).call(email: email),
    );
  }

  Future<void> verifyOtp({required String email, required String token}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => VerifyOtpUseCase(
        ref.read(authRepositoryProvider),
      ).call(email: email, token: token),
    );
    _refresh();
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
    _refresh();
    return result;
  }

  Future<void> activateAccount({required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ActivateAccountUseCase(
        ref.read(authRepositoryProvider),
      ).call(password: password),
    );
    _refresh();
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => SignOutUseCase(ref.read(authRepositoryProvider)).call(),
    );
    _refresh();
  }

  void _refresh() {
    ref.invalidate(currentProfileProvider);
    ref.invalidate(authStatusProvider);
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
