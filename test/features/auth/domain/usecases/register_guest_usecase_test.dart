import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sire/features/auth/domain/entities/auth_result.dart';
import 'package:sire/features/auth/domain/repositories/auth_repository.dart';
import 'package:sire/features/auth/domain/usecases/register_guest_usecase.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class FakeAuthResult extends Fake implements AuthResult {}

void main() {
  late RegisterGuestUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = RegisterGuestUseCase(mockRepository);
  });

  const tName = 'Juan Perez';
  const tEmail = 'juan@correo.com';
  const tPhone = '+56912345678';

  test('retorna exito al generar un registro de invitado', () async {
    final tAuthResult = FakeAuthResult();
    when(() => mockRepository.registerGuest(name: tName, email: tEmail, phone: tPhone))
        .thenAnswer((_) async => tAuthResult);

    final result = await useCase(name: tName, email: tEmail, phone: tPhone);

    expect(result, equals(tAuthResult));
    verify(() => mockRepository.registerGuest(name: tName, email: tEmail, phone: tPhone)).called(1);
  });
}