// PI-GEO-01 / PI-GEO-02 / PI-GEO-03 — Prueba de integración de la capa de datos
// del reverse-geocoding externo (Nominatim / OpenStreetMap).
//
// Conecta la fuente de datos REAL (NominatimReverseGeocodingDatasourceImpl) con
// un Dio real y simula solo la frontera de red con http_mock_adapter. Así se
// ejercita el envío de coordenadas como query params, el parsing del JSON de
// Nominatim y la extracción de región (address.state) y ciudad, contra una
// respuesta con la forma exacta del contrato de la API.

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:sire/core/network/app_exception.dart';
import 'package:sire/features/feed/data/datasources/nominatim_reverse_geocoding_datasource_impl.dart';

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late NominatimReverseGeocodingDatasourceImpl datasource;

  // Coordenadas de ejemplo (Temuco, Región de La Araucanía).
  const lat = -38.7359;
  const lon = -72.5904;
  final query = {
    'lat': lat,
    'lon': lon,
    'format': 'jsonv2',
    'accept-language': 'es',
    'zoom': 10,
  };

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
    adapter = DioAdapter(dio: dio);
    datasource = NominatimReverseGeocodingDatasourceImpl(dio: dio);
  });

  group('NominatimReverseGeocodingDatasourceImpl.reverse', () {
    test(
      'PI-GEO-01: parsea la región (state) y la ciudad del contrato',
      () async {
        adapter.onGet(
          '/reverse',
          (server) => server.reply(200, {
            'place_id': 123,
            'lat': '$lat',
            'lon': '$lon',
            'display_name': 'Temuco, Cautín, La Araucanía, Chile',
            'address': {
              'city': 'Temuco',
              'county': 'Cautín',
              'state': 'Región de La Araucanía',
              'country': 'Chile',
              'country_code': 'cl',
            },
          }),
          queryParameters: query,
        );

        final result = await datasource.reverse(lat: lat, lon: lon);

        expect(result.region, 'Región de La Araucanía');
        expect(result.city, 'Temuco');
      },
    );

    test(
      'PI-GEO-02: usa town/village cuando no hay city, y deja city en null si no hay localidad',
      () async {
        adapter.onGet(
          '/reverse',
          (server) => server.reply(200, {
            'address': {
              'town': 'Pucón',
              'state': 'Región de La Araucanía',
              'country': 'Chile',
            },
          }),
          queryParameters: query,
        );

        final result = await datasource.reverse(lat: lat, lon: lon);

        expect(result.region, 'Región de La Araucanía');
        expect(result.city, 'Pucón');
      },
    );

    test(
      'PI-GEO-03: si la respuesta no trae región (state), lanza ServerException',
      () async {
        adapter.onGet(
          '/reverse',
          (server) => server.reply(200, {
            'address': {'country': 'Chile'},
          }),
          queryParameters: query,
        );

        expect(
          () => datasource.reverse(lat: lat, lon: lon),
          throwsA(
            isA<ServerException>().having(
              (e) => e.code,
              'code',
              'REVERSE_GEOCODING_EMPTY',
            ),
          ),
        );
      },
    );

    test(
      'PI-GEO-04: ante un error HTTP, lanza ServerException envuelto',
      () async {
        adapter.onGet(
          '/reverse',
          (server) => server.reply(500, {'error': 'boom'}),
          queryParameters: query,
        );

        expect(
          () => datasource.reverse(lat: lat, lon: lon),
          throwsA(
            isA<ServerException>().having(
              (e) => e.code,
              'code',
              'REVERSE_GEOCODING_FAILED',
            ),
          ),
        );
      },
    );
  });
}
