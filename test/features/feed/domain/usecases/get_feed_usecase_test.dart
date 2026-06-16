import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sire/features/feed/domain/entities/feed_page.dart';
import 'package:sire/features/feed/domain/repositories/feed_repository.dart';
import 'package:sire/features/feed/domain/usecases/get_feed_usecase.dart';

class MockFeedRepository extends Mock implements FeedRepository {}
class FakeFeedPage extends Fake implements FeedPage {}

void main() {
  late GetFeedUseCase useCase;
  late MockFeedRepository mockRepository;

  setUp(() {
    mockRepository = MockFeedRepository();
    useCase = GetFeedUseCase(mockRepository);
  });

  const tRegion = 'Araucania';
  const tCity = 'Temuco';

  group('GetFeedUseCase', () {
    test('procesa y retorna lista vacia si el repositorio devuelve vacio', () async {
      const tFeedPageEmpty = FeedPage(
        items: [],
        page: 1,
        limit: 20,
        total: 0,
        hasMore: false,
        currentRegion: tRegion,
        currentOrder: FeedOrder.recent,
      );

      when(() => mockRepository.getFeed(region: tRegion, city: tCity, page: 1))
          .thenAnswer((_) async => tFeedPageEmpty);

      final result = await useCase(region: tRegion, city: tCity, page: 1);

      expect(result.items.isEmpty, true);
      verify(() => mockRepository.getFeed(region: tRegion, city: tCity, page: 1)).called(1);
    });

    test('retorna entidad FeedPage con datos si el repositorio devuelve datos', () async {
      final tFeedPage = FakeFeedPage();
      
      when(() => mockRepository.getFeed(region: tRegion, city: tCity, page: 1))
          .thenAnswer((_) async => tFeedPage);

      final result = await useCase(region: tRegion, city: tCity, page: 1);

      expect(result, equals(tFeedPage));
    });
  });
}