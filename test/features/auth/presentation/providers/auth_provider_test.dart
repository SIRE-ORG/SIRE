import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sire/features/auth/data/datasources/auth_remote_datasource_mock_impl.dart';
import 'package:sire/features/auth/data/datasources/avatar_storage_datasource.dart';
import 'package:sire/features/auth/domain/entities/auth_result.dart';
import 'package:sire/features/auth/domain/entities/user_profile.dart';
import 'package:sire/features/auth/domain/repositories/auth_repository.dart';
import 'package:sire/features/auth/presentation/providers/auth_provider.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockAvatarStorageDatasource extends Mock
    implements AvatarStorageDatasource {}

void main() {
  group('PI-PROV-03: flag por defecto selecciona el mock', () {
    test('sin overrides, el datasource remoto de auth es el mock', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(authRemoteDatasourceProvider),
        isA<AuthRemoteDatasourceMockImpl>(),
      );
    });
  });

  group('AuthNotifier', () {
    late MockAuthRepository mockRepository;

    setUp(() {
      mockRepository = MockAuthRepository();
    });

    ProviderContainer createContainer({List<Override> overrides = const []}) {
      final container = ProviderContainer(overrides: overrides);
      addTearDown(container.dispose);
      return container;
    }

    ProviderContainer withRepo() => createContainer(
      overrides: [authRepositoryProvider.overrideWithValue(mockRepository)],
    );

    test('estado inicial y mutacion al hacer login', () async {
      when(
        () => mockRepository.login(
          email: 'test@correo.com',
          password: 'password',
        ),
      ).thenAnswer((_) async {});

      final container = withRepo();

      final initialState = container.read(authNotifierProvider);
      expect(initialState, isA<AsyncData<void>>());

      final future = container
          .read(authNotifierProvider.notifier)
          .login(email: 'test@correo.com', password: 'password');

      expect(container.read(authNotifierProvider), isA<AsyncLoading<void>>());

      await future;

      expect(container.read(authNotifierProvider), isA<AsyncData<void>>());
      verify(
        () => mockRepository.login(
          email: 'test@correo.com',
          password: 'password',
        ),
      ).called(1);
    });

    test('login que falla deja el estado en AsyncError', () async {
      when(
        () => mockRepository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(Exception('credenciales inválidas'));

      final container = withRepo();

      await container
          .read(authNotifierProvider.notifier)
          .login(email: 'x@b.cl', password: 'mala');

      expect(container.read(authNotifierProvider).hasError, isTrue);
    });

    test('sendMagicLink transita loading → data', () async {
      when(
        () => mockRepository.sendMagicLink(email: any(named: 'email')),
      ).thenAnswer((_) async {});

      final container = withRepo();
      await container
          .read(authNotifierProvider.notifier)
          .sendMagicLink(email: 'a@b.cl');

      expect(container.read(authNotifierProvider), isA<AsyncData<void>>());
      verify(() => mockRepository.sendMagicLink(email: 'a@b.cl')).called(1);
    });

    test('verifyOtp transita loading → data', () async {
      when(
        () => mockRepository.verifyOtp(
          email: any(named: 'email'),
          token: any(named: 'token'),
        ),
      ).thenAnswer((_) async {});

      final container = withRepo();
      await container
          .read(authNotifierProvider.notifier)
          .verifyOtp(email: 'a@b.cl', token: '123456');

      expect(container.read(authNotifierProvider), isA<AsyncData<void>>());
    });

    test('registerGuest devuelve el AuthResult del repositorio', () async {
      const result = AuthResult(
        userId: 'u1',
        accountStatus: AccountStatus.guest,
        userCreated: true,
      );
      when(
        () => mockRepository.registerGuest(
          name: any(named: 'name'),
          email: any(named: 'email'),
          phone: any(named: 'phone'),
        ),
      ).thenAnswer((_) async => result);

      final container = withRepo();
      final out = await container
          .read(authNotifierProvider.notifier)
          .registerGuest(name: 'Dani', email: 'a@b.cl', phone: '+569');

      expect(out, result);
      expect(container.read(authNotifierProvider), isA<AsyncData<void>>());
    });

    test(
      'activateAccount con password válida transita loading → data',
      () async {
        when(
          () =>
              mockRepository.activateAccount(password: any(named: 'password')),
        ).thenAnswer((_) async {});

        final container = withRepo();
        await container
            .read(authNotifierProvider.notifier)
            .activateAccount(password: 'claveSegura123');

        expect(container.read(authNotifierProvider), isA<AsyncData<void>>());
        verify(
          () => mockRepository.activateAccount(password: 'claveSegura123'),
        ).called(1);
      },
    );

    test(
      'activateAccount con password corta → AsyncError (validación)',
      () async {
        final container = withRepo();

        await container
            .read(authNotifierProvider.notifier)
            .activateAccount(password: 'corta');

        expect(container.read(authNotifierProvider).hasError, isTrue);
        // La validación es del usecase: el repositorio nunca se invoca.
        verifyNever(
          () =>
              mockRepository.activateAccount(password: any(named: 'password')),
        );
      },
    );

    test('signOut transita loading → data', () async {
      when(() => mockRepository.signOut()).thenAnswer((_) async {});

      final container = withRepo();
      await container.read(authNotifierProvider.notifier).signOut();

      expect(container.read(authNotifierProvider), isA<AsyncData<void>>());
      verify(() => mockRepository.signOut()).called(1);
    });
  });

  group('currentProfile / authStatus', () {
    test('exponen el perfil y su accountStatus desde el repo', () async {
      final mockRepository = MockAuthRepository();
      const profile = UserProfile(
        id: 'u1',
        name: 'Dani',
        email: 'a@b.cl',
        phone: null,
        accountStatus: AccountStatus.active,
        emailVerified: true,
      );
      when(() => mockRepository.getProfile()).thenAnswer((_) async => profile);

      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(mockRepository)],
      );
      addTearDown(container.dispose);

      expect(await container.read(currentProfileProvider.future), profile);
      expect(
        await container.read(authStatusProvider.future),
        AccountStatus.active,
      );
    });
  });

  group('ProfileNotifier', () {
    test('updateProfile (sin avatar) transita loading → data', () async {
      final mockRepository = MockAuthRepository();
      const profile = UserProfile(
        id: 'u1',
        name: 'Dani',
        email: 'a@b.cl',
        phone: '+569',
        accountStatus: AccountStatus.active,
        emailVerified: true,
      );
      when(
        () => mockRepository.updateProfile(
          name: any(named: 'name'),
          phone: any(named: 'phone'),
          avatarUrl: any(named: 'avatarUrl'),
        ),
      ).thenAnswer((_) async => profile);

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepository),
          avatarStorageDatasourceProvider.overrideWithValue(
            MockAvatarStorageDatasource(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(profileNotifierProvider.notifier)
          .updateProfile(userId: 'u1', name: 'Dani', phone: '+569');

      expect(container.read(profileNotifierProvider), isA<AsyncData<void>>());
      verify(
        () => mockRepository.updateProfile(
          name: 'Dani',
          phone: '+569',
          avatarUrl: null,
        ),
      ).called(1);
    });
  });
}
