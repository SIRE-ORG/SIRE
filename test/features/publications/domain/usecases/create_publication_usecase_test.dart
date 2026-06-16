import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sire/features/publications/data/datasources/publication_image_datasource.dart';
import 'package:sire/features/publications/domain/entities/availability_config.dart';
import 'package:sire/features/publications/domain/entities/publication.dart';
import 'package:sire/features/publications/domain/repositories/publications_repository.dart';
import 'package:sire/features/publications/domain/usecases/create_publication_usecase.dart';

class MockPublicationsRepository extends Mock implements PublicationsRepository {}
class MockPublicationImageDatasource extends Mock implements PublicationImageDatasource {}
class FakePublication extends Fake implements Publication {}

void main() {
  late CreatePublicationUseCase useCase;
  late MockPublicationsRepository mockRepository;
  late MockPublicationImageDatasource mockImageDatasource;

  setUp(() {
    mockRepository = MockPublicationsRepository();
    mockImageDatasource = MockPublicationImageDatasource();
    
    useCase = CreatePublicationUseCase(
      repository: mockRepository,
      imageDatasource: mockImageDatasource,
    );
  });

  test('envia los parametros desglosados al repositorio sin fallar', () async {
    const tParams = CreatePublicationParams(
      title: 'Cancha',
      description: 'Cancha sintetica',
      category: PublicationCategory.deporte,
      region: 'Araucania',
      city: 'Temuco',
      availability: AvailabilityConfig(
        slotDurationMinutes: 60,
        sameScheduleAllDays: true,
        defaultSchedules: [
          DaySchedule(startTime: '09:00', endTime: '18:00')
        ],
        dayOverrides: [],
      ),
    );
    final tPublication = FakePublication();

    when(() => mockRepository.createPublication(
          title: tParams.title,
          description: tParams.description,
          category: tParams.category,
          imageUrl: null,
          region: tParams.region,
          city: tParams.city,
          availability: tParams.availability,
        )).thenAnswer((_) async => tPublication);

    final result = await useCase(params: tParams);

    expect(result, equals(tPublication));
    verify(() => mockRepository.createPublication(
          title: tParams.title,
          description: tParams.description,
          category: tParams.category,
          imageUrl: null,
          region: tParams.region,
          city: tParams.city,
          availability: tParams.availability,
        )).called(1);
    
    verifyNoMoreInteractions(mockRepository);
  });
}