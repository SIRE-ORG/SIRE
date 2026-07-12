// PI-PUB-01 / PI-PUB-02 / PI-PUB-03 (parte a) - Integración de la fuente de
// datos real de publicaciones contra HTTP simulado con la forma exacta del
// contrato del backend en dev (CRUD por id en un segmento; create/mine con
// el doble segmento del bug C).

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:sire/core/network/api_constants.dart';
import 'package:sire/core/network/app_exception.dart';
import 'package:sire/core/network/dio_client.dart';
import 'package:sire/features/publications/data/datasources/publications_remote_datasource_real_impl.dart';
import 'package:sire/features/publications/data/models/create_publication_request_model.dart';
import 'package:sire/features/publications/data/models/update_publication_request_model.dart';
import 'package:sire/features/publications/domain/entities/availability_config.dart';
import 'package:sire/features/publications/domain/entities/publication.dart';

import '../../../../helpers/fixtures.dart';
import '../../../../helpers/test_doubles.dart';

const _agenda = AvailabilityConfig(
  slotDurationMinutes: 60,
  sameScheduleAllDays: true,
  defaultSchedules: [DaySchedule(startTime: '09:00', endTime: '18:00')],
  dayOverrides: [
    DayOverride(dayOfWeek: DayOfWeek.sunday, isClosed: true, schedules: []),
  ],
);

const _solicitudCreacion = CreatePublicationRequestModel(
  title: 'Cancha Los Alerces',
  description: 'Cancha de futbol 7',
  category: PublicationCategory.deporte,
  region: 'Araucania',
  city: 'Temuco',
  availability: _agenda,
);

void main() {
  late Dio dio;
  late DioAdapter adapter;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
    adapter = DioAdapter(dio: dio);
    dio.interceptors.add(ErrorInterceptor());
  });

  PublicationsRemoteDatasourceRealImpl datasourceCon({String? userId}) =>
      PublicationsRemoteDatasourceRealImpl(
        dio: dio,
        supabase: supabaseWithUser(
          userId == null ? null : fakeUser(id: userId),
        ),
      );

  group('createPublication (PI-PUB-01, PI-PUB-03a)', () {
    test('201 del contrato -> modelo completo, con ownerId de la sesión en el '
        'payload', () async {
      // El matcher de data exacto verifica dos cosas a la vez: la forma del
      // payload del contrato y la inyección de ownerId desde la sesión.
      final payloadEsperado = {
        ..._solicitudCreacion.toJson(),
        'ownerId': 'user-1',
      };
      adapter.onPost(
        ApiConstants.publicationsFeedLive,
        (server) => server.reply(201, {
          'message': 'Publicación creada exitosamente',
          // POST devuelve la publicación sin include de owner.
          'data': publicationJson(ownerId: 'user-1', withOwner: false),
        }),
        data: payloadEsperado,
      );

      final model = await datasourceCon(
        userId: 'user-1',
      ).createPublication(body: _solicitudCreacion);

      expect(model.id, 'pub-1');
      expect(model.ownerId, 'user-1');
      expect(model.availability.slotDurationMinutes, 60);
      expect(model.availability.dayOverrides.single.dayOfWeek, 'SUNDAY');
      expect(model.availability.dayOverrides.single.isClosed, isTrue);
    });

    test('sin sesión lanza UnauthorizedException sin tocar la red', () async {
      // No se registra ningún mock: si el datasource intentara la petición,
      // el error sería de Dio, no el UnauthorizedException del guard.
      await expectLater(
        datasourceCon(userId: null).createPublication(body: _solicitudCreacion),
        throwsA(isA<UnauthorizedException>()),
      );
    });
  });

  group('getPublicationDetail (PI-PUB-02)', () {
    test('200 -> modelo con agenda y owner.name aplanado', () async {
      adapter.onGet(
        ApiConstants.publicationByIdLive('pub-1'),
        (server) => server.reply(200, {'data': publicationJson()}),
      );

      final model = await datasourceCon(
        userId: 'user-1',
      ).getPublicationDetail(id: 'pub-1');

      expect(model.title, 'Cancha Los Alerces');
      expect(model.ownerName, 'Club Andes');
      expect(model.availability.defaultSchedules.single.startTime, '09:00');
    });

    test('404 -> NotFoundException tipada en DioException.error', () async {
      adapter.onGet(
        ApiConstants.publicationByIdLive('no-existe'),
        (server) => server.reply(
          404,
          errorBody('NOT_FOUND', 'Publicación no encontrada'),
        ),
      );

      try {
        await datasourceCon(
          userId: 'user-1',
        ).getPublicationDetail(id: 'no-existe');
        fail('Se esperaba un DioException');
      } on DioException catch (e) {
        expect(e.error, isA<NotFoundException>());
        expect((e.error as NotFoundException).code, 'NOT_FOUND');
      }
    });

    test('respuesta sin availability no rompe el mapeo (tolerancia)', () async {
      final sinAgenda = publicationJson()..remove('availability');
      adapter.onGet(
        ApiConstants.publicationByIdLive('pub-1'),
        (server) => server.reply(200, {'data': sinAgenda}),
      );

      final model = await datasourceCon(
        userId: 'user-1',
      ).getPublicationDetail(id: 'pub-1');

      expect(model.availability.slotDurationMinutes, 60);
      expect(model.availability.defaultSchedules, isEmpty);
    });
  });

  group('rutas de escritura por id', () {
    test(
      'updatePublication usa PUT /publications/:id (un solo segmento)',
      () async {
        adapter.onPut(
          ApiConstants.publicationByIdLive('pub-1'),
          (server) => server.reply(200, {
            'message': 'Cancha actualizada',
            'data': publicationJson(title: 'Título nuevo', withOwner: false),
          }),
          data: Matchers.any,
        );

        final model = await datasourceCon(userId: 'user-1').updatePublication(
          id: 'pub-1',
          body: const UpdatePublicationRequestModel(title: 'Título nuevo'),
        );

        expect(model.title, 'Título nuevo');
      },
    );

    test('togglePublicationStatus viaja como PUT con {isActive}', () async {
      adapter.onPut(
        ApiConstants.publicationByIdLive('pub-1'),
        (server) => server.reply(200, {
          'message': 'Cancha actualizada',
          'data': publicationJson(isActive: false, withOwner: false),
        }),
        data: {'isActive': false},
      );

      await expectLater(
        datasourceCon(
          userId: 'user-1',
        ).togglePublicationStatus(id: 'pub-1', isActive: false),
        completes,
      );
    });

    test('deletePublication usa DELETE /publications/:id', () async {
      adapter.onDelete(
        ApiConstants.publicationByIdLive('pub-1'),
        (server) => server.reply(200, {
          'message': 'Publicación eliminada correctamente',
        }),
      );

      await expectLater(
        datasourceCon(userId: 'user-1').deletePublication(id: 'pub-1'),
        completes,
      );
    });
  });
}
