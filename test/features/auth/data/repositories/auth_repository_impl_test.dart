// PI-AUTH-REPO — AuthRepositoryImpl orquesta sus 3 colaboradores (Supabase
// Auth, backend REST y storage local) y mapea los modelos a entidades de
// dominio. Se mockean los colaboradores con mocktail; no toca red ni storage
// real.

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sire/core/network/app_exception.dart';
import 'package:sire/core/storage/local_storage_service.dart';
import 'package:sire/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:sire/features/auth/data/datasources/auth_supabase_datasource.dart';
import 'package:sire/features/auth/data/models/auth_response_model.dart';
import 'package:sire/features/auth/data/models/user_profile_model.dart';
import 'package:sire/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:sire/features/auth/domain/entities/auth_result.dart';
import 'package:sire/features/auth/domain/entities/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockAuthSupabaseDatasource extends Mock
    implements AuthSupabaseDatasource {}

class MockAuthRemoteDatasource extends Mock implements AuthRemoteDatasource {}

class MockLocalStorageService extends Mock implements LocalStorageService {}

void main() {
  late MockAuthSupabaseDatasource supa;
  late MockAuthRemoteDatasource remote;
  late MockLocalStorageService storage;
  late AuthRepositoryImpl repo;

  const profileModel = UserProfileModel(
    userId: 'u1',
    name: 'Dani',
    email: 'a@b.cl',
    phone: '+569',
    accountStatus: 'active',
    emailVerified: true,
    avatarUrl: null,
    createdAt: '2026-01-01T00:00:00Z',
  );

  setUpAll(() {
    registerFallbackValue(OtpType.email);
  });

  setUp(() {
    supa = MockAuthSupabaseDatasource();
    remote = MockAuthRemoteDatasource();
    storage = MockLocalStorageService();
    repo = AuthRepositoryImpl(
      supabaseDatasource: supa,
      remoteDatasource: remote,
      storage: storage,
    );
  });

  group('PI-AUTH-REPO: delegación a Supabase Auth', () {
    test('login delega en signInWithPassword', () async {
      when(
        () => supa.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async {});

      await repo.login(email: 'a@b.cl', password: 'pw');

      verify(
        () => supa.signInWithPassword(email: 'a@b.cl', password: 'pw'),
      ).called(1);
    });

    test('signInAnonymously sin sesión → delega en el datasource', () async {
      when(() => supa.getCurrentUserId()).thenReturn(null);
      when(() => supa.signInAnonymously()).thenAnswer((_) async {});

      await repo.signInAnonymously();

      verify(() => supa.signInAnonymously()).called(1);
    });

    test(
      'signInAnonymously con sesión existente → no-op (idempotente)',
      () async {
        when(() => supa.getCurrentUserId()).thenReturn('u1');

        await repo.signInAnonymously();

        verifyNever(() => supa.signInAnonymously());
      },
    );

    test('updateEmail delega en updateEmail del datasource', () async {
      when(
        () => supa.updateEmail(email: any(named: 'email')),
      ).thenAnswer((_) async {});

      await repo.updateEmail(email: 'nuevo@correo.cl');

      verify(() => supa.updateEmail(email: 'nuevo@correo.cl')).called(1);
    });

    test('sendMagicLink delega en signInWithOtp', () async {
      when(
        () => supa.signInWithOtp(email: any(named: 'email')),
      ).thenAnswer((_) async {});

      await repo.sendMagicLink(email: 'a@b.cl');

      verify(() => supa.signInWithOtp(email: 'a@b.cl')).called(1);
    });

    test('verifyOtp delega en verifyOtp del datasource con type por defecto '
        '(OtpType.email)', () async {
      when(
        () => supa.verifyOtp(
          email: any(named: 'email'),
          token: any(named: 'token'),
          type: any(named: 'type'),
        ),
      ).thenAnswer((_) async {});

      await repo.verifyOtp(email: 'a@b.cl', token: '123456');

      verify(
        () => supa.verifyOtp(
          email: 'a@b.cl',
          token: '123456',
          type: OtpType.email,
        ),
      ).called(1);
    });

    test('verifyOtp propaga type: OtpType.emailChange', () async {
      when(
        () => supa.verifyOtp(
          email: any(named: 'email'),
          token: any(named: 'token'),
          type: any(named: 'type'),
        ),
      ).thenAnswer((_) async {});

      await repo.verifyOtp(
        email: 'a@b.cl',
        token: '123456',
        type: OtpType.emailChange,
      );

      verify(
        () => supa.verifyOtp(
          email: 'a@b.cl',
          token: '123456',
          type: OtpType.emailChange,
        ),
      ).called(1);
    });

    test('signOut cierra sesión y borra el token de storage', () async {
      when(() => supa.signOut()).thenAnswer((_) async {});
      when(() => storage.delete(any())).thenAnswer((_) async {});

      await repo.signOut();

      verify(() => supa.signOut()).called(1);
      verify(() => storage.delete(StorageKeys.token)).called(1);
    });

    test('activateAccount actualiza password y estado de cuenta', () async {
      when(
        () => supa.updatePassword(password: any(named: 'password')),
      ).thenAnswer((_) async {});
      when(() => remote.updateAccountStatus()).thenAnswer((_) async {});

      await repo.activateAccount(password: 'nueva');

      verify(() => supa.updatePassword(password: 'nueva')).called(1);
      verify(() => remote.updateAccountStatus()).called(1);
    });

    test('authStateChanges reexpone el stream del datasource', () {
      when(
        () => supa.authStateChanges(),
      ).thenAnswer((_) => const Stream<AuthState>.empty());

      expect(repo.authStateChanges(), isA<Stream<AuthState>>());
      verify(() => supa.authStateChanges()).called(1);
    });
  });

  group('PI-AUTH-REPO: registerGuest', () {
    test('con token → lo persiste y devuelve AuthResult', () async {
      when(
        () => remote.registerGuest(
          name: any(named: 'name'),
          email: any(named: 'email'),
          phone: any(named: 'phone'),
        ),
      ).thenAnswer(
        (_) async => const AuthResponseModel(
          userId: 'u1',
          accountStatus: 'guest',
          userCreated: true,
          token: 'tok-1',
        ),
      );
      when(() => storage.write(any(), any())).thenAnswer((_) async {});

      final result = await repo.registerGuest(
        name: 'Dani',
        email: 'a@b.cl',
        phone: '+569',
      );

      expect(result, isA<AuthResult>());
      expect(result.userId, 'u1');
      expect(result.accountStatus, AccountStatus.guest);
      verify(() => storage.write(StorageKeys.token, 'tok-1')).called(1);
    });

    test('sin token → no escribe en storage', () async {
      when(
        () => remote.registerGuest(
          name: any(named: 'name'),
          email: any(named: 'email'),
          phone: any(named: 'phone'),
        ),
      ).thenAnswer(
        (_) async => const AuthResponseModel(
          userId: 'u2',
          accountStatus: 'guest',
          userCreated: true,
          token: null,
        ),
      );

      await repo.registerGuest(name: 'X', email: 'x@b.cl', phone: '1');

      verifyNever(() => storage.write(any(), any()));
    });
  });

  group('PI-AUTH-REPO: perfil', () {
    test('getProfile sin sesión → null y no consulta el backend', () async {
      when(() => supa.getCurrentUserId()).thenReturn(null);

      final p = await repo.getProfile();

      expect(p, isNull);
      verifyNever(() => remote.getProfile());
    });

    test('getProfile con sesión → entidad mapeada', () async {
      when(() => supa.getCurrentUserId()).thenReturn('u1');
      when(() => remote.getProfile()).thenAnswer((_) async => profileModel);

      final p = await repo.getProfile();

      expect(p, isA<UserProfile>());
      expect(p!.accountStatus, AccountStatus.active);
      expect(p.name, 'Dani');
    });

    test('getProfile con sesión anónima sin fila de perfil (404) → null, '
        'no propaga NotFoundException', () async {
      when(() => supa.getCurrentUserId()).thenReturn('anon-1');
      when(
        () => remote.getProfile(),
      ).thenThrow(NotFoundException(code: 'PROFILE_NOT_FOUND'));

      final p = await repo.getProfile();

      expect(p, isNull);
    });

    test('updateProfile → entidad mapeada', () async {
      when(
        () => remote.updateProfile(
          name: any(named: 'name'),
          phone: any(named: 'phone'),
          avatarUrl: any(named: 'avatarUrl'),
        ),
      ).thenAnswer((_) async => profileModel);

      final p = await repo.updateProfile(
        name: 'Dani',
        phone: '+569',
        avatarUrl: null,
      );

      expect(p.name, 'Dani');
    });
  });
}
