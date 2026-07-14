// PI-FEED-01 (cadena completa) / PI-FEED-03 - Integración de la capa de
// datos del feed: Dio real + interceptor de errores + datasource real +
// repositorio, simulando solo la frontera HTTP. Verifica que la respuesta
// del contrato termina en entidades de dominio completas.

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:sire/core/network/api_constants.dart';
import 'package:sire/core/network/app_exception.dart';
import 'package:sire/core/network/dio_client.dart';
import 'package:sire/core/storage/local_storage_service.dart';
import 'package:sire/features/feed/data/datasources/feed_remote_datasource_real_impl.dart';
import 'package:sire/features/feed/data/datasources/geo_datasource.dart';
import 'package:sire/features/feed/data/repositories/feed_repository_impl.dart';
import 'package:sire/features/feed/domain/entities/geo_location.dart';
import 'package:sire/features/publications/data/models/publication_detail_model.dart';
import 'package:sire/features/publications/domain/entities/publication.dart';

import '../../../../helpers/fixtures.dart';
import '../../../../helpers/test_doubles.dart';

/// GeoDatasource controlable: siempre devuelve [location].
class _StubGeoDatasource implements GeoDatasource {
  const _StubGeoDatasource(this.location);

  final GeoLocation location;

  @override
  Future<GeoLocation> getCurrentLocation() async => location;

  @override
  Future<bool> hasLocationPermission() async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Dio dio;
  late DioAdapter adapter;
  late FeedRepositoryImpl repository;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
    adapter = DioAdapter(dio: dio);
    dio.interceptors.add(ErrorInterceptor());
    repository = FeedRepositoryImpl(
      remoteDatasource: FeedRemoteDatasourceRealImpl(dio: dio),
      geoDatasource: const UnusedGeoDatasource(),
      storage: const LocalStorageService(),
    );
  });

  group('FeedRepositoryImpl.getFeed (PI-FEED-01)', () {
    test('respuesta del contrato -> entidades de dominio completas', () async {
      adapter.onGet(
        ApiConstants.publicationsFeedLive,
        (server) => server.reply(200, {
          'data': [
            publicationJson(category: 'DEPORTE'),
            publicationJson(
              id: 'pub-2',
              title: 'Yoga Namaste',
              category: 'RECREACION',
              ownerName: 'Emilia',
            ),
          ],
        }),
        queryParameters: {'region': 'Araucania'},
      );

      final page = await repository.getFeed(region: 'Araucania');

      expect(page.items, hasLength(2));
      final primera = page.items.first;
      expect(primera.id, 'pub-1');
      expect(primera.title, 'Cancha Los Alerces');
      // owner.name anidado -> aplanado -> entidad.
      expect(primera.ownerName, 'Club Andes');
      // Categoría del contrato en mayúsculas -> enum de dominio.
      expect(primera.category, PublicationCategory.deporte);
      expect(page.items.last.category, PublicationCategory.recreacion);
      // Metadatos de página que la UI usa para paginar y filtrar.
      expect(page.currentRegion, 'Araucania');
      expect(page.hasMore, isFalse);
    });

    test('error 500 del backend viaja como ServerException tipada', () async {
      adapter.onGet(
        ApiConstants.publicationsFeedLive,
        (server) => server.reply(
          500,
          errorBody('INTERNAL_SERVER_ERROR', 'Error al obtener'),
        ),
        queryParameters: {'region': 'Araucania'},
      );

      try {
        await repository.getFeed(region: 'Araucania');
        fail('Se esperaba un DioException');
      } on DioException catch (e) {
        // Convención del proyecto: el AppException viaja en DioException.error.
        expect(e.error, isA<ServerException>());
        expect((e.error as ServerException).code, 'INTERNAL_SERVER_ERROR');
      }
    });
  });

  group('Mapeo de categorías (PI-FEED-03)', () {
    test('ida y vuelta API ↔ enum sin pérdida para todo el enum', () {
      for (final categoria in PublicationCategory.values) {
        final api = publicationCategoryToString(categoria);
        expect(api, api.toUpperCase(), reason: 'la API exige mayúsculas');
        expect(publicationCategoryFromString(api), categoria);
      }
    });

    test('categoría desconocida degrada a otros sin romper', () {
      expect(
        publicationCategoryFromString('PILATES'),
        PublicationCategory.otros,
      );
      expect(publicationCategoryFromString(''), PublicationCategory.otros);
    });

    test('acepta la variante con tilde de recreación', () {
      expect(
        publicationCategoryFromString('RECREACIÓN'),
        PublicationCategory.recreacion,
      );
    });
  });

  group('FeedRepositoryImpl.detectRegion - cache de región y ciudad', () {
    FeedRepositoryImpl repoConGeo(GeoLocation location) => FeedRepositoryImpl(
      remoteDatasource: FeedRemoteDatasourceRealImpl(dio: dio),
      geoDatasource: _StubGeoDatasource(location),
      storage: const LocalStorageService(),
    );

    test('persiste región Y ciudad cuando el geocoding trae ambas', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final repo = repoConGeo(
        const GeoLocation(region: 'Región de La Araucanía', city: 'Temuco'),
      );

      final geo = await repo.detectRegion();

      expect(geo.region, 'Región de La Araucanía');
      expect(geo.city, 'Temuco');
      const storage = LocalStorageService();
      expect(await storage.read(StorageKeys.region), 'Región de La Araucanía');
      expect(await storage.read(StorageKeys.city), 'Temuco');
    });

    test('sin ciudad en el geocoding solo persiste la región', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final repo = repoConGeo(
        const GeoLocation(region: 'Región Metropolitana'),
      );

      await repo.detectRegion();

      const storage = LocalStorageService();
      expect(await storage.read(StorageKeys.region), 'Región Metropolitana');
      expect(await storage.read(StorageKeys.city), isNull);
    });
  });
}
