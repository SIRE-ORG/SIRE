import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sire/features/publications/domain/repositories/publications_repository.dart';
import 'package:sire/features/publications/domain/usecases/get_my_publications_usecase.dart';

class MockPublicationsRepository extends Mock implements PublicationsRepository {}
class FakeMyPublicationsResult extends Fake implements MyPublicationsResult {}

void main() {
  late GetMyPublicationsUseCase useCase;
  late MockPublicationsRepository mockRepository;

  setUp(() {
    mockRepository = MockPublicationsRepository();
    useCase = GetMyPublicationsUseCase(mockRepository);
  });

  test('retorna el MyPublicationsResult especifico del publicador', () async {
    final tResult = FakeMyPublicationsResult();
    const tPage = 1;
    const tLimit = 20;

    when(() => mockRepository.getMyPublications(page: tPage, limit: tLimit))
        .thenAnswer((_) async => tResult);

    final result = await useCase(page: tPage, limit: tLimit);

    expect(result, equals(tResult));
    verify(() => mockRepository.getMyPublications(page: tPage, limit: tLimit)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });
}