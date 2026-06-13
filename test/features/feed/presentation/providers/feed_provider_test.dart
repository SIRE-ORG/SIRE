// PI-PROV-02 / PI-PROV-03 — Providers del feed con la fuente de datos
// sustituida. El FeedNotifier.build() lee la región cacheada de
// FlutterSecureStorage, por lo que esta suite requiere binding de widgets y
// mock de secure storage.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sire/core/network/app_exception.dart';
import 'package:sire/features/feed/data/datasources/feed_remote_datasource.dart';
import 'package:sire/features/feed/data/datasources/feed_remote_datasource_mock_impl.dart';
import 'package:sire/features/feed/data/models/feed_response_model.dart';
import 'package:sire/features/feed/data/models/publication_summary_model.dart';
import 'package:sire/features/feed/presentation/providers/feed_provider.dart';
import 'package:sire/features/publications/domain/entities/publication.dart';

import '../../../../helpers/test_doubles.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Región cacheada para que build() NUNCA llame al GeoDatasource.
    FlutterSecureStorage.setMockInitialValues({'last_region': 'Araucania'});
  });

  /// Crea un [ProviderContainer] con los datasources sustituidos.
  ProviderContainer containerCon(FeedRemoteDatasource datasource) {
    final container = ProviderContainer(
      overrides: [
        feedRemoteDatasourceProvider.overrideWithValue(datasource),
        // Defensa: si el cache de región fallara, la prueba falla con
        // StateError claro en vez de un error oscuro de canal de plataforma.
        geoDatasourceProvider.overrideWithValue(const UnusedGeoDatasource()),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('PI-PROV-01: carga → datos', () {
    test('el notifier entrega FeedPage con entidades mapeadas y región del '
        'cache', () async {
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

      expect(container.read(feedNotifierProvider).isLoading, isTrue);

      final page = await container.read(feedNotifierProvider.future);

      expect(page.items.single.category, PublicationCategory.deporte);
      expect(page.currentRegion, 'Araucania');

      sub.close();
    });
  });

  group('PI-PROV-02: error del repositorio → AsyncError', () {
    test(
      'el error se propaga como estado sin excepción sin capturar',
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

  group('PI-PROV-03: flag por defecto selecciona el mock', () {
    test('sin overrides, el datasource es FeedRemoteDatasourceMockImpl', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(feedRemoteDatasourceProvider),
        isA<FeedRemoteDatasourceMockImpl>(),
      );
    });
  });
}
