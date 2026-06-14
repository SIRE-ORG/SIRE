import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sire/features/publications/domain/repositories/publications_repository.dart';
import 'package:sire/features/publications/domain/usecases/toggle_publication_status_usecase.dart';

class MockPublicationsRepository extends Mock implements PublicationsRepository {}

void main() {
  late TogglePublicationStatusUseCase useCase;
  late MockPublicationsRepository mockRepository;

  setUp(() {
    mockRepository = MockPublicationsRepository();
    useCase = TogglePublicationStatusUseCase(mockRepository);
  });

  test('procesa la solicitud para cambiar estado usando isActive', () async {
    const tId = 'pub-123';
    const tIsActive = false;
    
    when(() => mockRepository.togglePublicationStatus(id: tId, isActive: tIsActive))
        .thenAnswer((_) async {});

    await useCase(id: tId, isActive: tIsActive);

    verify(() => mockRepository.togglePublicationStatus(id: tId, isActive: tIsActive)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });
}