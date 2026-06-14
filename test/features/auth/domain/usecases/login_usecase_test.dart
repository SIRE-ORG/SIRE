import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sire/features/auth/domain/repositories/auth_repository.dart';
import 'package:sire/features/auth/domain/usecases/login_usecase.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late LoginUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = LoginUseCase(mockRepository);
  });

  const tEmail = 'test@correo.com';
  const tPassword = 'password123';

  group('LoginUseCase', () {
    test('retorna exitoso invocando al repositorio simulado con credenciales validas', () async {
      when(() => mockRepository.login(email: tEmail, password: tPassword))
          .thenAnswer((_) async {});

      await useCase(email: tEmail, password: tPassword);

      verify(() => mockRepository.login(email: tEmail, password: tPassword)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('atrape la excepcion y retorne un error controlado al simular fallo', () async {
      when(() => mockRepository.login(email: tEmail, password: tPassword))
          .thenAnswer((_) async => throw Exception('Credenciales inválidas'));

      await expectLater(
        () => useCase(email: tEmail, password: tPassword),
        throwsA(isA<Exception>()),
      );

      verify(() => mockRepository.login(email: tEmail, password: tPassword)).called(1);
    });
  });
}