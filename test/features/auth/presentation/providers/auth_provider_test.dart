import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sire/features/auth/data/datasources/auth_remote_datasource_mock_impl.dart';
import 'package:sire/features/auth/domain/repositories/auth_repository.dart';
import 'package:sire/features/auth/presentation/providers/auth_provider.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

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

    ProviderContainer createContainer({
      List<Override> overrides = const [],
    }) {
      final container = ProviderContainer(overrides: overrides);
      addTearDown(container.dispose);
      return container;
    }

    test('estado inicial y mutacion al hacer login', () async {
      when(() => mockRepository.login(email: 'test@correo.com', password: 'password'))
          .thenAnswer((_) async {});

      final container = createContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );

      final initialState = container.read(authNotifierProvider);
      expect(initialState, isA<AsyncData<void>>());

      final future = container.read(authNotifierProvider.notifier).login(
            email: 'test@correo.com',
            password: 'password',
          );

      expect(container.read(authNotifierProvider), isA<AsyncLoading<void>>());

      await future;

      expect(container.read(authNotifierProvider), isA<AsyncData<void>>());
      verify(() => mockRepository.login(email: 'test@correo.com', password: 'password')).called(1);
    });
  });
}