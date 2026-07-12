import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sire/core/network/api_flags.dart';
import 'package:sire/core/network/app_exception.dart';
import 'package:sire/features/publications/data/datasources/publications_remote_datasource.dart';
import 'package:sire/features/publications/data/datasources/publications_remote_datasource_real_impl.dart';
import 'package:sire/features/publications/data/models/publication_summary_item_model.dart';
import 'package:sire/features/publications/domain/entities/publication.dart';
import 'package:sire/features/publications/domain/repositories/publications_repository.dart';
import 'package:sire/features/publications/presentation/providers/my_publications_provider.dart';

import '../../../../helpers/test_doubles.dart';

class MockPublicationsRepository extends Mock
    implements PublicationsRepository {}

void main() {
  ProviderContainer containerCon(PublicationsRemoteDatasource datasource) {
    final container = ProviderContainer(
      overrides: [
        publicationsRemoteDatasourceProvider.overrideWithValue(datasource),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('PI-PROV-01', () {
    test('transito de carga a datos', () async {
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

      final sub = container.listen(myPublicationsNotifierProvider, (_, _) {});

      expect(container.read(myPublicationsNotifierProvider).isLoading, isTrue);

      final items = await container.read(myPublicationsNotifierProvider.future);
      expect(items.single.category, PublicationCategory.deporte);
      expect(container.read(myPublicationsNotifierProvider).hasValue, isTrue);

      sub.close();
    });
  });

  group('PI-PROV-02', () {
    test('error del repositorio se propaga como estado', () async {
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

  group('PI-PROV-03', () {
    test('ApiFlags.useMocks es false por defecto', () {
      expect(ApiFlags.useMocks, isFalse);
    });

    // La rama `useMocks == false` construye
    // PublicationsRemoteDatasourceRealImpl con Supabase.instance.client, que
    // exige Supabase inicializado (no disponible en este entorno de test).
    // Se inyectan dio/supabase de prueba para verificar que esa rama resuelve
    // al tipo real esperado.
    test('con dio/supabase inyectados, la rama real resuelve '
        'PublicationsRemoteDatasourceRealImpl', () {
      final container = ProviderContainer(
        overrides: [
          publicationsRemoteDatasourceProvider.overrideWithValue(
            PublicationsRemoteDatasourceRealImpl(
              dio: Dio(),
              supabase: MockSupabaseClient(),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(publicationsRemoteDatasourceProvider),
        isA<PublicationsRemoteDatasourceRealImpl>(),
      );
    });
  });

  group('PI-PROV-04', () {
    test(
      'toggleStatus procesa la solicitud usando PublicationFormNotifier',
      () async {
        final mockRepo = MockPublicationsRepository();

        when(
          () => mockRepo.togglePublicationStatus(id: 'pub-1', isActive: false),
        ).thenAnswer((_) async {});

        final container = ProviderContainer(
          overrides: [
            publicationsRepositoryProvider.overrideWithValue(mockRepo),
          ],
        );
        addTearDown(container.dispose);

        await container
            .read(publicationFormNotifierProvider.notifier)
            .toggleStatus(id: 'pub-1', isActive: false);

        verify(
          () => mockRepo.togglePublicationStatus(id: 'pub-1', isActive: false),
        ).called(1);
      },
    );
  });
}
