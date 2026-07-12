// PI-FEED-01..05 - Prueba de integración de la capa de datos del feed.
//
// Conecta la fuente de datos REAL (FeedRemoteDatasourceRealImpl) con un Dio real,
// simulando solo la frontera de red con http_mock_adapter. Así se ejercita el
// parsing JSON real, la construcción de modelos, la extracción de owner.name y
// el fallback sin filtro de región, contra respuestas con la forma exacta del
// contrato de API.

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:sire/core/network/api_constants.dart';
import 'package:sire/features/feed/data/datasources/feed_remote_datasource_real_impl.dart';

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late FeedRemoteDatasourceRealImpl datasource;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
    adapter = DioAdapter(dio: dio);
    datasource = FeedRemoteDatasourceRealImpl(dio: dio);
  });

  group('FeedRemoteDatasourceRealImpl.getFeed', () {
    test(
      'PI-FEED-01/03: parsea la respuesta del contrato y mapea owner.name y categoría',
      () async {
        adapter.onGet(
          ApiConstants.publicationsFeedLive,
          (server) => server.reply(200, {
            'data': [
              {
                'id': 'pub-1',
                'title': 'Cancha Los Alerces',
                'description': 'Cancha de futbol 7',
                'region': 'Araucania',
                'category': 'DEPORTE',
                'ownerId': 'owner-9',
                'owner': {'name': 'Club Andes'},
                'createdAt': '2026-06-01T12:00:00Z',
              },
            ],
          }),
          queryParameters: {'region': 'Araucania'},
        );

        final result = await datasource.getFeed(region: 'Araucania');

        expect(result.items, hasLength(1));
        final item = result.items.first;
        expect(item.id, 'pub-1');
        expect(item.title, 'Cancha Los Alerces');
        // El nombre del dueño viene anidado en owner.name; el datasource lo aplana.
        expect(item.ownerName, 'Club Andes');
        // La categoría se conserva en mayúsculas (el mapeo a enum ocurre en el modelo -> entidad).
        expect(item.category, 'DEPORTE');
      },
    );

    test('PI-FEED-02: envía el parámetro region en el query', () async {
      // El matcher de queryParameters actúa como aserción: si el datasource no
      // manda region=Maule, no hay mock que responda y la prueba falla.
      adapter.onGet(
        ApiConstants.publicationsFeedLive,
        (server) => server.reply(200, {
          'data': [
            {
              'id': 'pub-m',
              'title': 'Pub Maule',
              'description': '',
              'region': 'Maule',
              'category': 'OTROS',
              'ownerId': 'o',
              'owner': {'name': 'X'},
              'createdAt': '2026-06-01T12:00:00Z',
            },
          ],
        }),
        queryParameters: {'region': 'Maule'},
      );

      final result = await datasource.getFeed(region: 'Maule');

      expect(result.items, hasLength(1));
    });

    test(
      'PI-FEED-04: si la región no devuelve nada, reintenta sin filtro (fallback)',
      () async {
        // Primer intento (con región) -> vacío.
        adapter.onGet(
          ApiConstants.publicationsFeedLive,
          (server) => server.reply(200, {'data': []}),
          queryParameters: {'region': 'RegionQueNoMatchea'},
        );
        // Reintento (sin región) -> trae publicaciones.
        adapter.onGet(
          ApiConstants.publicationsFeedLive,
          (server) => server.reply(200, {
            'data': [
              {
                'id': 'pub-x',
                'title': 'Pub Global',
                'description': '',
                'region': 'La Araucania',
                'category': 'OTROS',
                'ownerId': 'o',
                'owner': {'name': 'X'},
                'createdAt': '2026-06-01T12:00:00Z',
              },
            ],
          }),
          queryParameters: {},
        );

        final result = await datasource.getFeed(region: 'RegionQueNoMatchea');

        expect(result.items, hasLength(1));
        expect(result.items.first.title, 'Pub Global');
      },
    );

    test(
      'PI-FEED-05: si ni con región ni sin ella hay datos, el feed queda vacío sin romper',
      () async {
        // Con región -> vacío.
        adapter.onGet(
          ApiConstants.publicationsFeedLive,
          (server) => server.reply(200, {'data': []}),
          queryParameters: {'region': 'Araucania'},
        );
        // Fallback sin región -> también vacío.
        adapter.onGet(
          ApiConstants.publicationsFeedLive,
          (server) => server.reply(200, {'data': []}),
          queryParameters: {},
        );

        final result = await datasource.getFeed(region: 'Araucania');

        expect(result.items, isEmpty);
      },
    );
  });
}
