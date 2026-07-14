// S3-3 - UpdateProfileUseCase sube el avatar ANTES del PUT /users/me: si el
// upload al storage falla (buckets de Supabase en configuración), el error
// tipado AvatarUploadException debe llegar a la UI sin ejecutar el PUT, para
// que la pantalla lo distinga del fallo de guardado.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sire/features/auth/data/datasources/avatar_storage_datasource.dart';
import 'package:sire/features/auth/domain/entities/auth_result.dart';
import 'package:sire/features/auth/domain/entities/user_profile.dart';
import 'package:sire/features/auth/domain/repositories/auth_repository.dart';
import 'package:sire/features/auth/domain/usecases/update_profile_usecase.dart';

const _kProfile = UserProfile(
  id: 'user-1',
  name: 'Juan Pérez',
  email: 'juan@sire.cl',
  accountStatus: AccountStatus.active,
  emailVerified: true,
);

/// AuthRepository que solo implementa [updateProfile], registrando las
/// invocaciones y el avatarUrl recibido; el resto no debe llamarse.
class _RecordingAuthRepository implements AuthRepository {
  int updateProfileCalls = 0;
  String? lastAvatarUrl;

  @override
  Future<UserProfile> updateProfile({
    String? name,
    String? phone,
    String? avatarUrl,
  }) async {
    updateProfileCalls++;
    lastAvatarUrl = avatarUrl;
    return _kProfile;
  }

  @override
  Future<void> login({required String email, required String password}) =>
      throw UnimplementedError();

  @override
  Future<void> signInAnonymously() => throw UnimplementedError();

  @override
  Future<void> sendMagicLink({required String email}) =>
      throw UnimplementedError();

  @override
  Future<void> verifyOtp({
    required String email,
    required String token,
    OtpType type = OtpType.email,
  }) => throw UnimplementedError();

  @override
  Future<void> updateEmail({required String email}) =>
      throw UnimplementedError();

  @override
  Future<void> signOut() => throw UnimplementedError();

  @override
  Future<AuthResult> registerGuest({
    required String name,
    required String email,
    required String phone,
  }) => throw UnimplementedError();

  @override
  Future<void> activateAccount({required String password}) =>
      throw UnimplementedError();

  @override
  Future<UserProfile?> getProfile() => throw UnimplementedError();

  @override
  Stream<AuthState> authStateChanges() => throw UnimplementedError();
}

/// AvatarStorageDatasource controlable: lanza [error] o devuelve [url].
class _StubAvatarStorageDatasource implements AvatarStorageDatasource {
  _StubAvatarStorageDatasource({this.url = '', this.error});

  final String url;
  final Object? error;
  int uploadCalls = 0;

  @override
  Future<String> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    required String extension,
  }) async {
    uploadCalls++;
    if (error != null) throw error!;
    return url;
  }
}

void main() {
  final bytes = Uint8List.fromList([1, 2, 3]);

  test(
    'si el upload del avatar falla, lanza AvatarUploadException y NO ejecuta '
    'el PUT del perfil',
    () async {
      final repo = _RecordingAuthRepository();
      final storage = _StubAvatarStorageDatasource(
        error: AvatarUploadException(message: 'Bucket not found'),
      );
      final useCase = UpdateProfileUseCase(
        repository: repo,
        avatarDatasource: storage,
      );

      await expectLater(
        useCase.call(
          userId: 'user-1',
          name: 'Juan',
          avatarBytes: bytes,
          avatarExtension: 'jpg',
        ),
        throwsA(isA<AvatarUploadException>()),
      );

      expect(storage.uploadCalls, 1);
      expect(repo.updateProfileCalls, 0);
    },
  );

  test('con upload exitoso, el PUT recibe la URL pública del avatar', () async {
    final repo = _RecordingAuthRepository();
    final storage = _StubAvatarStorageDatasource(
      url: 'https://cdn.sire.cl/avatars/user-1.jpg',
    );
    final useCase = UpdateProfileUseCase(
      repository: repo,
      avatarDatasource: storage,
    );

    await useCase.call(
      userId: 'user-1',
      name: 'Juan',
      avatarBytes: bytes,
      avatarExtension: 'jpg',
    );

    expect(storage.uploadCalls, 1);
    expect(repo.updateProfileCalls, 1);
    expect(repo.lastAvatarUrl, 'https://cdn.sire.cl/avatars/user-1.jpg');
  });

  test(
    'sin imagen seleccionada no toca el storage y el PUT va sin avatarUrl',
    () async {
      final repo = _RecordingAuthRepository();
      final storage = _StubAvatarStorageDatasource();
      final useCase = UpdateProfileUseCase(
        repository: repo,
        avatarDatasource: storage,
      );

      await useCase.call(userId: 'user-1', name: 'Juan');

      expect(storage.uploadCalls, 0);
      expect(repo.updateProfileCalls, 1);
      expect(repo.lastAvatarUrl, isNull);
    },
  );
}
