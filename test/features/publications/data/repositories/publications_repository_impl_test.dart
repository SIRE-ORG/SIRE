// PI-PUB-01 / PI-PUB-02 (cadena completa) — Repositorio + datasource real +
// Dio con interceptor de errores: la respuesta del contrato termina en una
// entidad Publication de dominio con su agenda tipada.

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:sire/core/network/api_constants.dart';
import 'package:sire/core/network/app_exception.dart';
import 'package:sire/core/network/dio_client.dart';
import 'package:sire/features/publications/data/datasources/publications_remote_datasource_real_impl.dart';
import 'package:sire/features/publications/data/repositories/publications_repository_impl.dart';
import 'package:sire/features/publications/domain/entities/availability_config.dart';
import 'package:sire/features/publications/domain/entities/publication.dart';

import '../../../../helpers/fixtures.dart';
import '../../../../helpers/test_doubles.dart';

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late PublicationsRepositoryImpl repository;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
    adapter = DioAdapter(dio: dio);
    dio.interceptors.add(ErrorInterceptor());
    repository = PublicationsRepositoryImpl(
      remoteDatasource: PublicationsRemoteDatasourceRealImpl(
        dio: dio,
        supabase: supabaseWithUser(fakeUser(id: 'user-1')),
      ),
    );
  });

  test('crear publicación → entidad de dominio completa con agenda tipada '
      '(PI-PUB-01)', () async {
    adapter.onPost(
      ApiConstants.publicationsFeedLive,
      (server) => server.reply(201, {
        'message': 'Publicación creada exitosamente',
        'data': publicationJson(ownerId: 'user-1', withOwner: false),
      }),
      data: Matchers.any,
    );

    final publication = await repository.createPublication(
      title: 'Cancha Los Alerces',
      description: 'Cancha de futbol 7',
      category: PublicationCategory.deporte,
      region: 'Araucania',
      city: 'Temuco',
      availability: const AvailabilityConfig(
        slotDurationMinutes: 60,
        sameScheduleAllDays: true,
        defaultSchedules: [DaySchedule(startTime: '09:00', endTime: '18:00')],
        dayOverrides: [],
      ),
    );

    expect(publication, isA<Publication>());
    expect(publication.category, PublicationCategory.deporte);
    expect(publication.isActive, isTrue);
    // La agenda llega tipada hasta el dominio: día como enum, no string.
    expect(
      publication.availability.dayOverrides.single.dayOfWeek,
      DayOfWeek.sunday,
    );
    expect(publication.availability.defaultSchedules.single.endTime, '18:00');
  });

  test(
    'detalle por id → entidad con ownerName del include (PI-PUB-02)',
    () async {
      adapter.onGet(
        ApiConstants.publicationByIdLive('pub-1'),
        (server) => server.reply(200, {'data': publicationJson()}),
      );

      final publication = await repository.getPublicationDetail(id: 'pub-1');

      expect(publication.ownerName, 'Club Andes');
      expect(publication.availability.slotDurationMinutes, 60);
    },
  );

  test(
    'detalle por id inexistente → NotFoundException tipada (PI-PUB-02)',
    () async {
      adapter.onGet(
        ApiConstants.publicationByIdLive('fantasma'),
        (server) => server.reply(
          404,
          errorBody('NOT_FOUND', 'Publicación no encontrada'),
        ),
      );

      try {
        await repository.getPublicationDetail(id: 'fantasma');
        fail('Se esperaba un DioException');
      } on DioException catch (e) {
        expect(e.error, isA<NotFoundException>());
      }
    },
  );
}
