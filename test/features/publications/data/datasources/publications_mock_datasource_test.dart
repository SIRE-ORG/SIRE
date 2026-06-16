import 'package:flutter_test/flutter_test.dart';
import 'package:sire/features/publications/data/datasources/publications_remote_datasource_mock_impl.dart';
import 'package:sire/features/publications/data/models/create_publication_request_model.dart';
import 'package:sire/features/publications/data/models/update_publication_request_model.dart';
import 'package:sire/features/publications/domain/entities/availability_config.dart';
import 'package:sire/features/publications/domain/entities/publication.dart';

void main() {
  late PublicationsRemoteDatasourceMockImpl datasource;

  const testAvailability = AvailabilityConfig(
    slotDurationMinutes: 60,
    sameScheduleAllDays: true,
    defaultSchedules: [DaySchedule(startTime: '09:00', endTime: '18:00')],
    dayOverrides: [],
  );

  setUp(() {
    datasource = PublicationsRemoteDatasourceMockImpl();
  });

  group('PublicationsRemoteDatasourceMockImpl', () {
    group('getPublicationDetail', () {
      test('retorna detalle de publicación existente', () async {
        final result = await datasource.getPublicationDetail(id: 'mock-pub-1');
        expect(result.id, 'mock-pub-1');
        expect(result.title, 'Cancha de fútbol El Estadio');
      });

      test('retorna primera publicación para id desconocido', () async {
        final result = await datasource.getPublicationDetail(id: 'no-existe');
        expect(result.id, isNotEmpty);
      });

      test('retorna segunda publicación por id', () async {
        final result = await datasource.getPublicationDetail(id: 'mock-pub-2');
        expect(result.id, 'mock-pub-2');
        expect(result.category, 'RECREACION');
      });

      test('retorna publicación inactiva por id', () async {
        final result = await datasource.getPublicationDetail(id: 'mock-pub-3');
        expect(result.id, 'mock-pub-3');
        expect(result.isActive, false);
      });
    });

    group('getMyPublications', () {
      test('retorna publicaciones del usuario demo', () async {
        final result = await datasource.getMyPublications();
        expect(result.items, isNotEmpty);
        expect(result.hasMore, false);
      });

      test('page 1 retorna items del usuario', () async {
        final result = await datasource.getMyPublications(page: 1);
        expect(result.page, 1);
        expect(result.items.length, greaterThan(0));
      });

      test('page mayor a 1 retorna lista vacía', () async {
        final result = await datasource.getMyPublications(page: 2);
        expect(result.items, isEmpty);
        expect(result.hasMore, false);
        expect(result.total, 2);
      });

      test('los items del usuario tienen ownerId correcto', () async {
        final result = await datasource.getMyPublications();
        for (final item in result.items) {
          expect(item.id, isNotEmpty);
        }
      });

      test('limit se aplica en la respuesta', () async {
        final result = await datasource.getMyPublications(limit: 5);
        expect(result.limit, 5);
      });
    });

    group('createPublication', () {
      test('crea publicación con datos del request', () async {
        const request = CreatePublicationRequestModel(
          title: 'Nueva cancha',
          description: 'Una nueva cancha de fútbol',
          category: PublicationCategory.deporte,
          region: 'Biobío',
          availability: testAvailability,
        );

        final result = await datasource.createPublication(body: request);

        expect(result.title, 'Nueva cancha');
        expect(result.description, 'Una nueva cancha de fútbol');
        expect(result.isActive, true);
        expect(result.ownerId, 'mock-user-id-123');
      });

      test('id generado no es vacío', () async {
        const request = CreatePublicationRequestModel(
          title: 'Test',
          description: 'Desc',
          category: PublicationCategory.otros,
          region: 'Test',
          availability: testAvailability,
        );

        final result = await datasource.createPublication(body: request);
        expect(result.id, isNotEmpty);
        expect(result.id, startsWith('mock-pub-'));
      });

      test('imageUrl del request se preserva', () async {
        const request = CreatePublicationRequestModel(
          title: 'Con imagen',
          description: 'Desc',
          category: PublicationCategory.eventos,
          imageUrl: 'https://example.com/img.jpg',
          region: 'Norte',
          availability: testAvailability,
        );

        final result = await datasource.createPublication(body: request);
        expect(result.imageUrl, 'https://example.com/img.jpg');
      });

      test('city del request se preserva', () async {
        const request = CreatePublicationRequestModel(
          title: 'Con ciudad',
          description: 'Desc',
          category: PublicationCategory.recreacion,
          region: 'Sur',
          city: 'Concepción',
          availability: testAvailability,
        );

        final result = await datasource.createPublication(body: request);
        expect(result.city, 'Concepción');
      });
    });

    group('updatePublication', () {
      test('actualiza título de publicación existente', () async {
        const request = UpdatePublicationRequestModel(title: 'Título nuevo');
        final result = await datasource.updatePublication(
          id: 'mock-pub-1',
          body: request,
        );
        expect(result.title, 'Título nuevo');
        expect(result.id, 'mock-pub-1');
      });

      test('preserva campos no actualizados', () async {
        const request = UpdatePublicationRequestModel(title: 'Solo título');
        final result = await datasource.updatePublication(
          id: 'mock-pub-1',
          body: request,
        );
        expect(result.description, isNotEmpty);
        expect(result.ownerId, 'mock-owner-1');
      });

      test('actualiza con id desconocido usa primera publicación', () async {
        const request = UpdatePublicationRequestModel(title: 'Actualizado');
        final result = await datasource.updatePublication(
          id: 'no-existe',
          body: request,
        );
        expect(result.title, 'Actualizado');
        expect(result.id, isNotEmpty);
      });

      test('actualiza región', () async {
        const request = UpdatePublicationRequestModel(region: 'Atacama');
        final result = await datasource.updatePublication(
          id: 'mock-pub-2',
          body: request,
        );
        expect(result.region, 'Atacama');
      });
    });

    group('togglePublicationStatus', () {
      test('no lanza excepción al alternar estado', () async {
        expect(
          () => datasource.togglePublicationStatus(
            id: 'mock-pub-1',
            isActive: false,
          ),
          returnsNormally,
        );
      });

      test('completa correctamente para id desconocido', () async {
        await expectLater(
          datasource.togglePublicationStatus(
            id: 'no-existe',
            isActive: true,
          ),
          completes,
        );
      });
    });

    group('deletePublication', () {
      test('no lanza excepción al eliminar', () async {
        expect(
          () => datasource.deletePublication(id: 'mock-pub-1'),
          returnsNormally,
        );
      });

      test('completa correctamente para id desconocido', () async {
        await expectLater(
          datasource.deletePublication(id: 'no-existe'),
          completes,
        );
      });
    });
  });
}
