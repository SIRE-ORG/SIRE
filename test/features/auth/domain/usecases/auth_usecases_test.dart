import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:sire/features/auth/data/datasources/avatar_storage_datasource.dart';
import 'package:sire/features/auth/domain/entities/auth_result.dart';
import 'package:sire/features/auth/domain/entities/user_profile.dart';
import 'package:sire/features/auth/domain/repositories/auth_repository.dart';
import 'package:sire/features/auth/domain/usecases/activate_account_usecase.dart';
import 'package:sire/features/auth/domain/usecases/get_profile_usecase.dart';
import 'package:sire/features/auth/domain/usecases/login_usecase.dart';
import 'package:sire/features/auth/domain/usecases/register_guest_usecase.dart';
import 'package:sire/features/auth/domain/usecases/send_magic_link_usecase.dart';
import 'package:sire/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:sire/features/auth/domain/usecases/update_profile_usecase.dart';
import 'package:sire/features/auth/domain/usecases/verify_otp_usecase.dart';
import 'package:sire/core/network/app_exception.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockAvatarDatasource extends Mock implements AvatarStorageDatasource {}

const _kProfile = UserProfile(
  id: 'u1',
  name: 'Test',
  email: 't@t.com',
  accountStatus: AccountStatus.active,
  emailVerified: true,
);

const _kAuthResult = AuthResult(
  userId: 'u1',
  accountStatus: AccountStatus.guest,
  userCreated: true,
);

void main() {
  late _MockAuthRepository repo;

  setUp(() {
    repo = _MockAuthRepository();
  });

  group('LoginUseCase', () {
    test('delega al repositorio con email y password', () async {
      when(
        () => repo.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async {});

      await LoginUseCase(repo).call(email: 'a@b.com', password: 'pass123');

      verify(() => repo.login(email: 'a@b.com', password: 'pass123')).called(1);
    });
  });

  group('RegisterGuestUseCase', () {
    test('delega al repositorio y retorna AuthResult', () async {
      when(
        () => repo.registerGuest(
          name: any(named: 'name'),
          email: any(named: 'email'),
          phone: any(named: 'phone'),
        ),
      ).thenAnswer((_) async => _kAuthResult);

      final result = await RegisterGuestUseCase(
        repo,
      ).call(name: 'Test', email: 'a@b.com', phone: '123');

      expect(result.userId, equals('u1'));
      expect(result.userCreated, isTrue);
    });
  });

  group('ActivateAccountUseCase', () {
    test('delega al repositorio cuando la contraseña es válida', () async {
      when(
        () => repo.activateAccount(password: any(named: 'password')),
      ).thenAnswer((_) async {});

      await ActivateAccountUseCase(repo).call(password: 'password123');

      verify(() => repo.activateAccount(password: 'password123')).called(1);
    });

    test(
      'lanza ValidationException si la contraseña tiene menos de 8 chars',
      () {
        expect(
          () => ActivateAccountUseCase(repo).call(password: 'short'),
          throwsA(isA<ValidationException>()),
        );
        verifyNever(
          () => repo.activateAccount(password: any(named: 'password')),
        );
      },
    );
  });

  group('SendMagicLinkUseCase', () {
    test('delega al repositorio con el email', () async {
      when(
        () => repo.sendMagicLink(email: any(named: 'email')),
      ).thenAnswer((_) async {});

      await SendMagicLinkUseCase(repo).call(email: 'a@b.com');

      verify(() => repo.sendMagicLink(email: 'a@b.com')).called(1);
    });
  });

  group('SignOutUseCase', () {
    test('delega al repositorio', () async {
      when(() => repo.signOut()).thenAnswer((_) async {});

      await SignOutUseCase(repo).call();

      verify(() => repo.signOut()).called(1);
    });
  });

  group('GetProfileUseCase', () {
    test('retorna perfil desde el repositorio', () async {
      when(() => repo.getProfile()).thenAnswer((_) async => _kProfile);

      final result = await GetProfileUseCase(repo).call();

      expect(result?.id, equals('u1'));
    });

    test('retorna null si no hay sesión activa', () async {
      when(() => repo.getProfile()).thenAnswer((_) async => null);

      final result = await GetProfileUseCase(repo).call();

      expect(result, isNull);
    });
  });

  group('UpdateProfileUseCase', () {
    late _MockAvatarDatasource avatar;

    setUp(() {
      avatar = _MockAvatarDatasource();
    });

    test('actualiza perfil sin imagen', () async {
      // Usa valores explícitos para evitar problemas con String? nullable en any()
      when(
        () => repo.updateProfile(name: 'Nuevo', phone: '999', avatarUrl: null),
      ).thenAnswer((_) async => _kProfile);

      final result = await UpdateProfileUseCase(
        repository: repo,
        avatarDatasource: avatar,
      ).call(userId: 'u1', name: 'Nuevo', phone: '999');

      expect(result.id, equals('u1'));
      expect(result.name, equals('Test'));
    });
  });

  group('VerifyOtpUseCase', () {
    test('delega al repositorio con email y token', () async {
      when(
        () => repo.verifyOtp(
          email: any(named: 'email'),
          token: any(named: 'token'),
        ),
      ).thenAnswer((_) async {});

      await VerifyOtpUseCase(repo).call(email: 'a@b.com', token: '123456');

      verify(() => repo.verifyOtp(email: 'a@b.com', token: '123456')).called(1);
    });
  });
}
