import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sire/features/feed/domain/entities/geo_location.dart';
import 'package:sire/features/feed/domain/repositories/feed_repository.dart';
import 'package:sire/features/feed/domain/usecases/detect_region_usecase.dart';

class MockFeedRepository extends Mock implements FeedRepository {}

void main() {
  late DetectRegionUseCase useCase;
  late MockFeedRepository mockRepository;

  setUp(() {
    mockRepository = MockFeedRepository();
    useCase = DetectRegionUseCase(mockRepository);
  });

  test('devuelve una GeoLocation correcta cuando el repositorio responde bien', () async {
    const tLocation = GeoLocation(region: 'Araucania', city: 'Temuco');
    
    when(() => mockRepository.detectRegion())
        .thenAnswer((_) async => tLocation);

    final result = await useCase();

    expect(result.region, equals('Araucania'));
    expect(result.city, equals('Temuco'));
    verify(() => mockRepository.detectRegion()).called(1);
  });
}