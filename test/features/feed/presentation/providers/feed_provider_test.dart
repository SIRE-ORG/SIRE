import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sire/core/network/api_flags.dart';
import 'package:sire/core/network/app_exception.dart';
import 'package:sire/core/storage/local_storage_service.dart';
import 'package:sire/features/feed/data/datasources/feed_remote_datasource.dart';
import 'package:sire/features/feed/data/datasources/feed_remote_datasource_real_impl.dart';
import 'package:sire/features/feed/data/models/feed_response_model.dart';
import 'package:sire/features/feed/data/models/publication_summary_model.dart';
import 'package:sire/features/feed/presentation/providers/feed_provider.dart';
import 'package:sire/features/publications/domain/entities/publication.dart';
import '../../../../helpers/test_doubles.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({'last_region': 'Araucania'});
  });

  ProviderContainer containerCon(FeedRemoteDatasource datasource) {
    final container = ProviderContainer(
      overrides: [
        feedRemoteDatasourceProvider.overrideWithValue(datasource),
        geoDatasourceProvider.overrideWithValue(const UnusedGeoDatasource()),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('PI-PROV-01: carga -> datos', () {
    test(
      'estado inicial AsyncLoading y pasa a AsyncData al resolver la peticion',
      () async {
        final container = containerCon(
          StubFeedRemoteDatasource(
            response: FeedResponseModel(
              items: [
                PublicationSummaryModel(
                  id: 'pub-1',
                  title: 'Cancha',
                  description: '',
                  region: 'Araucania',
                  category: 'DEPORTE',
                  ownerName: 'Club',
                  ownerId: 'o1',
                  createdAt: '',
                ),
              ],
              page: 1,
              limit: 1,
              total: 1,
              hasMore: false,
            ),
          ),
        );

        final sub = container.listen(feedNotifierProvider, (_, _) {});

        expect(container.read(feedNotifierProvider), isA<AsyncLoading>());

        final page = await container.read(feedNotifierProvider.future);

        final finalState = container.read(feedNotifierProvider);
        expect(finalState, isA<AsyncData>());

        expect(page.items.single.category, PublicationCategory.deporte);
        expect(page.currentRegion, 'Araucania');

        sub.close();
      },
    );
  });

  group('PI-PROV-02: error del repositorio -> AsyncError', () {
    test(
      'el error se propaga como estado sin excepcion sin capturar',
      () async {
        final container = containerCon(
          StubFeedRemoteDatasource(error: NetworkException()),
        );

        await expectLater(
          container.read(feedNotifierProvider.future),
          throwsA(isA<NetworkException>()),
        );

        expect(container.read(feedNotifierProvider).hasError, isTrue);
      },
    );
  });

  group('PI-PROV-03: flag por defecto selecciona el backend real', () {
    test('ApiFlags.useMocks es false por defecto', () {
      expect(ApiFlags.useMocks, isFalse);
    });

    test('sin overrides, el datasource es FeedRemoteDatasourceRealImpl', () {
      dotenv.testLoad(fileInput: 'API_BASE_URL=http://localhost:3000/api/v1');
      addTearDown(dotenv.clean);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(feedRemoteDatasourceProvider),
        isA<FeedRemoteDatasourceRealImpl>(),
      );
    });
  });

  // S3-2: filtro de región con opción "Todas las regiones" (region null).
  group('filtro de región (S3-2)', () {
    RecordingFeedRemoteDatasource recordingDatasource() =>
        RecordingFeedRemoteDatasource(
          response: const FeedResponseModel(
            items: [],
            page: 1,
            limit: 20,
            total: 0,
            hasMore: false,
          ),
        );

    test('el default inicial sigue siendo la región cacheada', () async {
      final datasource = recordingDatasource();
      final container = containerCon(datasource);
      final sub = container.listen(feedNotifierProvider, (_, _) {});
      addTearDown(sub.close);

      final page = await container.read(feedNotifierProvider.future);

      expect(datasource.regionCalls, ['Araucania']);
      expect(page.currentRegion, 'Araucania');
    });

    test('seleccionar "Todas las regiones" (null) dispara el fetch sin región '
        'y no pisa la región cacheada', () async {
      final datasource = recordingDatasource();
      final container = containerCon(datasource);
      final sub = container.listen(feedNotifierProvider, (_, _) {});
      addTearDown(sub.close);
      await container.read(feedNotifierProvider.future);

      await container
          .read(feedNotifierProvider.notifier)
          .setRegionManually(null);

      expect(datasource.regionCalls.last, isNull);
      expect(container.read(feedNotifierProvider).value?.currentRegion, isNull);
      // "Todas" es un filtro de sesión: la cacheada sigue siendo el
      // default inicial para la próxima carga.
      const storage = LocalStorageService();
      expect(await storage.read(StorageKeys.region), 'Araucania');
    });

    test(
      'seleccionar una región concreta manda esa región y la persiste',
      () async {
        final datasource = recordingDatasource();
        final container = containerCon(datasource);
        final sub = container.listen(feedNotifierProvider, (_, _) {});
        addTearDown(sub.close);
        await container.read(feedNotifierProvider.future);

        await container
            .read(feedNotifierProvider.notifier)
            .setRegionManually('Región del Maule');

        expect(datasource.regionCalls.last, 'Región del Maule');
        expect(
          container.read(feedNotifierProvider).value?.currentRegion,
          'Región del Maule',
        );
        const storage = LocalStorageService();
        expect(await storage.read(StorageKeys.region), 'Región del Maule');
      },
    );
  });
}
