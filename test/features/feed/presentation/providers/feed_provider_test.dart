import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sire/core/network/api_flags.dart';
import 'package:sire/core/network/app_exception.dart';
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
}
