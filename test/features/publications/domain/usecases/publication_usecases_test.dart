import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:sire/features/publications/data/datasources/publication_image_datasource.dart';
import 'package:sire/features/publications/domain/entities/availability_config.dart';
import 'package:sire/features/publications/domain/entities/publication.dart';
import 'package:sire/features/publications/domain/repositories/publications_repository.dart';
import 'package:sire/features/publications/domain/usecases/create_publication_usecase.dart';
import 'package:sire/features/publications/domain/usecases/delete_publication_usecase.dart';
import 'package:sire/features/publications/domain/usecases/get_my_publications_usecase.dart';
import 'package:sire/features/publications/domain/usecases/get_publication_detail_usecase.dart';
import 'package:sire/features/publications/domain/usecases/toggle_publication_status_usecase.dart';
import 'package:sire/features/publications/domain/usecases/update_publication_usecase.dart';

class _MockPublicationsRepository extends Mock
    implements PublicationsRepository {}

class _MockImageDatasource extends Mock implements PublicationImageDatasource {}

const _kAvailability = AvailabilityConfig(
  slotDurationMinutes: 60,
  sameScheduleAllDays: true,
  defaultSchedules: [DaySchedule(startTime: '09:00', endTime: '18:00')],
  dayOverrides: [],
);

final _kPublication = Publication(
  id: 'pub-1',
  title: 'Cancha',
  description: 'Desc',
  region: 'Temuco',
  category: PublicationCategory.deporte,
  ownerId: 'u1',
  ownerName: 'Owner',
  isActive: true,
  availability: _kAvailability,
  createdAt: '2026-01-01',
);

void main() {
  late _MockPublicationsRepository repo;
  late _MockImageDatasource imageDatasource;

  setUp(() {
    repo = _MockPublicationsRepository();
    imageDatasource = _MockImageDatasource();
    registerFallbackValue(PublicationCategory.deporte);
    registerFallbackValue(_kAvailability);
    registerFallbackValue(Uint8List(0));
  });

  group('CreatePublicationUseCase', () {
    test('crea publicación sin imagen', () async {
      when(() => repo.createPublication(
                title: any(named: 'title'),
                description: any(named: 'description'),
                category: any(named: 'category'),
                imageUrl: any(named: 'imageUrl'),
                region: any(named: 'region'),
                city: any(named: 'city'),
                availability: any(named: 'availability'),
              ))
          .thenAnswer((_) async => _kPublication);

      final result = await CreatePublicationUseCase(
        repository: repo,
        imageDatasource: imageDatasource,
      ).call(
        params: CreatePublicationParams(
          title: 'Cancha',
          description: 'Desc',
          category: PublicationCategory.deporte,
          region: 'Temuco',
          availability: _kAvailability,
        ),
      );

      expect(result.id, equals('pub-1'));
      verifyNever(() => imageDatasource.uploadImage(
            bytes: any(named: 'bytes'),
            extension: any(named: 'extension'),
          ));
    });
  });

  group('UpdatePublicationUseCase', () {
    test('actualiza publicación sin nueva imagen', () async {
      // Usa valores explícitos para parámetros nullable (Mocktail requirement)
      when(() => repo.updatePublication(
                id: 'pub-1',
                title: 'Nueva cancha',
                description: null,
                category: null,
                imageUrl: null,
                region: null,
                city: null,
                availability: null,
              ))
          .thenAnswer((_) async => _kPublication);

      final result = await UpdatePublicationUseCase(
        repository: repo,
        imageDatasource: imageDatasource,
      ).call(
        id: 'pub-1',
        params: const UpdatePublicationParams(title: 'Nueva cancha'),
      );

      expect(result.id, equals('pub-1'));
    });
  });

  group('DeletePublicationUseCase', () {
    test('delega al repositorio con el id correcto', () async {
      when(() => repo.deletePublication(id: 'pub-1'))
          .thenAnswer((_) async {});

      await DeletePublicationUseCase(repo).call(id: 'pub-1');

      verify(() => repo.deletePublication(id: 'pub-1')).called(1);
    });
  });

  group('GetPublicationDetailUseCase', () {
    test('retorna publicación desde el repositorio', () async {
      when(() => repo.getPublicationDetail(id: 'pub-1'))
          .thenAnswer((_) async => _kPublication);

      final result =
          await GetPublicationDetailUseCase(repo).call(id: 'pub-1');

      expect(result.title, equals('Cancha'));
    });
  });

  group('GetMyPublicationsUseCase', () {
    test('retorna resultado paginado desde el repositorio', () async {
      final mockResult = MyPublicationsResult(
        items: const [],
        page: 1,
        hasMore: false,
        total: 0,
      );
      when(() => repo.getMyPublications(page: 1, limit: 20))
          .thenAnswer((_) async => mockResult);

      final result = await GetMyPublicationsUseCase(repo).call();

      expect(result.page, equals(1));
      expect(result.hasMore, isFalse);
    });
  });

  group('TogglePublicationStatusUseCase', () {
    test('delega al repositorio con id e isActive', () async {
      when(() => repo.togglePublicationStatus(id: 'pub-1', isActive: false))
          .thenAnswer((_) async {});

      await TogglePublicationStatusUseCase(repo)
          .call(id: 'pub-1', isActive: false);

      verify(() =>
              repo.togglePublicationStatus(id: 'pub-1', isActive: false))
          .called(1);
    });
  });
}
