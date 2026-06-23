// PI-PROV-04 / PI-PROV-05 / PI-PROV-06 — Providers de reservas con la
// fuente de datos sustituida: tránsito de estados sin excepciones sin capturar.
//
// Sin binding de widgets: MyReservationsNotifier no depende de storage ni
// canales de plataforma. Solo se sustituye el datasource remoto.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sire/core/network/app_exception.dart';
import 'package:sire/features/reservations/data/datasources/reservations_remote_datasource.dart';
import 'package:sire/features/reservations/data/datasources/reservations_remote_datasource_mock_impl.dart';
import 'package:sire/features/reservations/data/models/reservation_model.dart';
import 'package:sire/features/reservations/domain/entities/reservation.dart';
import 'package:sire/features/reservations/presentation/providers/reservations_provider.dart';

import '../../../../helpers/test_doubles.dart';

void main() {
  /// Crea un [ProviderContainer] con el datasource sustituido por [datasource].
  ProviderContainer containerCon(ReservationsRemoteDatasource datasource) {
    final container = ProviderContainer(
      overrides: [
        reservationsRemoteDatasourceProvider.overrideWithValue(datasource),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('PI-PROV-04: tránsito de carga a datos', () {
    test('el notifier arranca cargando y entrega entidades mapeadas', () async {
      final container = containerCon(
        StubReservationsRemoteDatasource(
          myResponse: [
            const ReservationModel(
              id: 'res-1',
              publicationId: 'pub-1',
              date: '2026-06-20',
              startTime: '10:00',
              endTime: '11:00',
              status: 'pending',
              createdAt: '2026-06-15T12:00:00Z',
              publicationTitle: 'Cancha',
              publicationCity: 'Temuco',
              publicationImageUrl: null,
            ),
          ],
        ),
      );

      final sub = container.listen(myReservationsNotifierProvider, (_, _) {});

      // Estado inicial: cargando.
      expect(container.read(myReservationsNotifierProvider).isLoading, isTrue);

      // Al resolverse el future, la entidad llega con status mapeado.
      final items = await container.read(myReservationsNotifierProvider.future);
      expect(items.single.status, ReservationStatus.pending);
      expect(items.single.publicationTitle, 'Cancha');
      expect(container.read(myReservationsNotifierProvider).hasValue, isTrue);

      sub.close();
    });
  });

  group('PI-PROV-05: error del repositorio → AsyncError, sin excepción sin '
      'capturar', () {
    test('el error se propaga como estado y no rompe el test', () async {
      final container = containerCon(
        StubReservationsRemoteDatasource(
          error: ServerException(
            code: 'INTERNAL_SERVER_ERROR',
            message: 'boom',
          ),
        ),
      );

      await expectLater(
        container.read(myReservationsNotifierProvider.future),
        throwsA(isA<ServerException>()),
      );

      expect(container.read(myReservationsNotifierProvider).hasError, isTrue);
    });
  });

  group('PI-PROV-06: flag por defecto selecciona la implementación mock', () {
    test('sin overrides, el datasource es el mock', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(reservationsRemoteDatasourceProvider),
        isA<ReservationsRemoteDatasourceMockImpl>(),
      );
    });
  });

  group('PI-PROV-07: recibidas (lado publisher) — espejo de PI-PROV-04/05', () {
    test('el notifier de recibidas carga y mapea las entidades', () async {
      final container = containerCon(
        StubReservationsRemoteDatasource(
          receivedResponse: [
            const ReservationModel(
              id: 'res-rx-1',
              publicationId: 'pub-mia-1',
              date: '2026-06-21',
              startTime: '09:00',
              endTime: '10:00',
              status: 'pending',
              createdAt: '2026-06-15T12:00:00Z',
              publicationTitle: 'Mi cancha',
              publicationCity: 'Temuco',
              publicationImageUrl: null,
            ),
          ],
        ),
      );

      expect(
        container.read(receivedReservationsNotifierProvider).isLoading,
        isTrue,
      );

      final items = await container.read(
        receivedReservationsNotifierProvider.future,
      );
      expect(items.single.status, ReservationStatus.pending);
      expect(items.single.publicationTitle, 'Mi cancha');
      expect(
        container.read(receivedReservationsNotifierProvider).hasValue,
        isTrue,
      );
    });

    test('el error del repositorio se propaga como AsyncError', () async {
      final container = containerCon(
        StubReservationsRemoteDatasource(
          error: ServerException(
            code: 'INTERNAL_SERVER_ERROR',
            message: 'boom',
          ),
        ),
      );

      await expectLater(
        container.read(receivedReservationsNotifierProvider.future),
        throwsA(isA<ServerException>()),
      );

      expect(
        container.read(receivedReservationsNotifierProvider).hasError,
        isTrue,
      );
    });
  });
}
