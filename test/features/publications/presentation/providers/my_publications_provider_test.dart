// PI-PROV-01 / PI-PROV-02 / PI-PROV-03 — Providers de publicaciones con la
// fuente de datos sustituida: tránsito de estados sin excepciones sin capturar.
//
// Sin binding de widgets: MyPublicationsNotifier no depende de storage ni
// canales de plataforma. Solo se sustituye el datasource remoto.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sire/core/network/app_exception.dart';
import 'package:sire/features/publications/data/datasources/publications_remote_datasource.dart';
import 'package:sire/features/publications/data/datasources/publications_remote_datasource_mock_impl.dart';
import 'package:sire/features/publications/data/models/publication_summary_item_model.dart';
import 'package:sire/features/publications/domain/entities/publication.dart';
import 'package:sire/features/publications/presentation/providers/my_publications_provider.dart';

import '../../../../helpers/test_doubles.dart';

void main() {
  /// Crea un [ProviderContainer] con el datasource sustituido por [datasource].
  ProviderContainer containerCon(PublicationsRemoteDatasource datasource) {
    final container = ProviderContainer(
      overrides: [
        publicationsRemoteDatasourceProvider.overrideWithValue(datasource),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('PI-PROV-01: tránsito de carga a datos', () {
    test('el notifier arranca cargando y entrega entidades mapeadas', () async {
      final container = containerCon(
        StubPublicationsRemoteDatasource(
          mineResponse: MyPublicationsResponse(
            items: [
              PublicationSummaryItemModel(
                id: 'pub-1',
                title: 'Cancha',
                category: 'DEPORTE',
                region: 'Araucania',
                isActive: true,
                createdAt: '2026-06-01T12:00:00Z',
              ),
            ],
            page: 1,
            limit: 1,
            total: 1,
            hasMore: false,
          ),
        ),
      );

      // Se mantiene una suscripción viva para que el provider no se disponga
      // antes de que el test termine.
      final sub = container.listen(myPublicationsNotifierProvider, (_, _) {});

      // Estado inicial: cargando.
      expect(container.read(myPublicationsNotifierProvider).isLoading, isTrue);

      // Al resolverse el future, la entidad llega con categoría mapeada.
      final items = await container.read(myPublicationsNotifierProvider.future);
      expect(items.single.category, PublicationCategory.deporte);
      expect(container.read(myPublicationsNotifierProvider).hasValue, isTrue);

      sub.close();
    });
  });

  group('PI-PROV-02: error del repositorio → AsyncError, sin excepción sin '
      'capturar', () {
    test('el error se propaga como estado y no rompe el test', () async {
      final container = containerCon(
        StubPublicationsRemoteDatasource(
          error: ServerException(
            code: 'INTERNAL_SERVER_ERROR',
            message: 'boom',
          ),
        ),
      );

      await expectLater(
        container.read(myPublicationsNotifierProvider.future),
        throwsA(isA<ServerException>()),
      );

      expect(container.read(myPublicationsNotifierProvider).hasError, isTrue);
    });
  });

  group('PI-PROV-03: flag por defecto selecciona la implementación mock', () {
    test('sin overrides, el datasource es el mock', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(publicationsRemoteDatasourceProvider),
        isA<PublicationsRemoteDatasourceMockImpl>(),
      );
    });
  });
}
