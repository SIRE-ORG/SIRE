// PI-PROV-04 / PI-PROV-05 / PI-PROV-06 - Providers de reservas con la
// fuente de datos sustituida: tránsito de estados sin excepciones sin capturar.
//
// Sin binding de widgets: MyReservationsNotifier no depende de storage ni
// canales de plataforma. Solo se sustituye el datasource remoto.

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sire/core/network/api_flags.dart';
import 'package:sire/core/network/app_exception.dart';
import 'package:sire/features/reservations/data/datasources/reservations_remote_datasource.dart';
import 'package:sire/features/reservations/data/datasources/reservations_remote_datasource_real_impl.dart';
import 'package:sire/features/reservations/data/models/reservation_model.dart';
import 'package:sire/features/reservations/domain/entities/reservation.dart';
import 'package:sire/features/reservations/domain/usecases/create_reservation_usecase.dart';
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

  group('PI-PROV-05: error del repositorio -> AsyncError, sin excepción sin '
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

  group('PI-PROV-06: flag por defecto selecciona el backend real', () {
    test('ApiFlags.useMocks es false por defecto', () {
      expect(ApiFlags.useMocks, isFalse);
    });

    test('sin overrides, el datasource es la implementación real', () {
      dotenv.testLoad(fileInput: 'API_BASE_URL=http://localhost:3000/api/v1');
      addTearDown(dotenv.clean);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(reservationsRemoteDatasourceProvider),
        isA<ReservationsRemoteDatasourceRealImpl>(),
      );
    });
  });

  group('PI-PROV-07: recibidas (lado publisher) - espejo de PI-PROV-04/05', () {
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

  group('PI-PROV-08: acciones (crear / actualizar estado / cancelar)', () {
    const actionModel = ReservationModel(
      id: 'res-new',
      publicationId: 'pub-1',
      date: '2026-06-25',
      startTime: '10:00',
      endTime: '11:00',
      status: 'pending',
      createdAt: '2026-06-20T12:00:00Z',
    );

    const params = CreateReservationParams(
      publicationId: 'pub-1',
      date: '2026-06-25',
      startTime: '10:00',
      endTime: '11:00',
    );

    test(
      'create: éxito -> devuelve la entidad e invalida "mis reservas"',
      () async {
        final stub = StubReservationsRemoteDatasource(
          actionResponse: actionModel,
          myResponse: const [],
        );
        final container = containerCon(stub);
        // Mantener viva la lista para observar la invalidación.
        container.listen(myReservationsNotifierProvider, (_, _) {});
        await container.read(myReservationsNotifierProvider.future);
        final callsAntes = stub.myReservationsCalls;

        final notifier = container.read(
          reservationActionNotifierProvider.notifier,
        );
        final created = await notifier.create(params: params);

        expect(created.id, 'res-new');
        expect(created.status, ReservationStatus.pending);
        expect(
          container.read(reservationActionNotifierProvider).hasValue,
          isTrue,
        );

        // La invalidación forzó un refetch de la lista del solicitante.
        await container.read(myReservationsNotifierProvider.future);
        expect(stub.myReservationsCalls, greaterThan(callsAntes));
      },
    );

    test('create: error del repositorio -> AsyncError y relanza', () async {
      final container = containerCon(
        StubReservationsRemoteDatasource(
          error: ServerException(code: 'CONFLICT', message: 'slot ocupado'),
        ),
      );
      final notifier = container.read(
        reservationActionNotifierProvider.notifier,
      );

      await expectLater(
        notifier.create(params: params),
        throwsA(isA<ServerException>()),
      );
      expect(
        container.read(reservationActionNotifierProvider).hasError,
        isTrue,
      );
    });

    test(
      'updateStatus: éxito -> mapea el enum a string e invalida "recibidas"',
      () async {
        final stub = StubReservationsRemoteDatasource(
          actionResponse: actionModel,
          receivedResponse: const [],
        );
        final container = containerCon(stub);
        container.listen(receivedReservationsNotifierProvider, (_, _) {});
        await container.read(receivedReservationsNotifierProvider.future);
        final callsAntes = stub.receivedReservationsCalls;

        final notifier = container.read(
          reservationActionNotifierProvider.notifier,
        );
        final updated = await notifier.updateStatus(
          id: 'res-new',
          status: ReservationStatus.completed,
        );

        expect(updated.id, 'res-new');
        // El repositorio mapea el enum a su nombre en minúsculas.
        expect(stub.lastStatusArg, 'completed');
        expect(
          container.read(reservationActionNotifierProvider).hasValue,
          isTrue,
        );

        // updateStatus es acción del publisher -> refresca "recibidas", no "mías".
        await container.read(receivedReservationsNotifierProvider.future);
        expect(stub.receivedReservationsCalls, greaterThan(callsAntes));
      },
    );

    test('updateStatus: error -> AsyncError y relanza', () async {
      final container = containerCon(
        StubReservationsRemoteDatasource(
          error: ServerException(code: 'NOT_FOUND', message: 'no existe'),
        ),
      );
      final notifier = container.read(
        reservationActionNotifierProvider.notifier,
      );

      await expectLater(
        notifier.updateStatus(id: 'nope', status: ReservationStatus.rejected),
        throwsA(isA<ServerException>()),
      );
      expect(
        container.read(reservationActionNotifierProvider).hasError,
        isTrue,
      );
    });

    test('cancel: éxito -> AsyncData e invalida "mis reservas"', () async {
      final stub = StubReservationsRemoteDatasource(
        actionResponse: actionModel,
        myResponse: const [],
      );
      final container = containerCon(stub);
      container.listen(myReservationsNotifierProvider, (_, _) {});
      await container.read(myReservationsNotifierProvider.future);
      final callsAntes = stub.myReservationsCalls;

      final notifier = container.read(
        reservationActionNotifierProvider.notifier,
      );
      await notifier.cancel(id: 'res-new');

      expect(
        container.read(reservationActionNotifierProvider).hasValue,
        isTrue,
      );
      await container.read(myReservationsNotifierProvider.future);
      expect(stub.myReservationsCalls, greaterThan(callsAntes));
    });

    test(
      'cancel: error -> AsyncError sin relanzar (usa AsyncValue.guard)',
      () async {
        final container = containerCon(
          StubReservationsRemoteDatasource(
            error: ServerException(
              code: 'INTERNAL_SERVER_ERROR',
              message: 'boom',
            ),
          ),
        );
        final notifier = container.read(
          reservationActionNotifierProvider.notifier,
        );

        // cancel usa guard: no relanza, solo deja el estado en error.
        await notifier.cancel(id: 'res-new');
        expect(
          container.read(reservationActionNotifierProvider).hasError,
          isTrue,
        );
      },
    );
  });

  group('PI-PROV-09: detalle de una reserva por id', () {
    const detalle = ReservationModel(
      id: 'res-1',
      publicationId: 'pub-1',
      date: '2026-06-25',
      startTime: '10:00',
      endTime: '11:00',
      status: 'completed',
      createdAt: '2026-06-20T12:00:00Z',
      publicationTitle: 'Cancha',
      publicationCity: 'Temuco',
      publicationImageUrl: null,
    );

    test('éxito -> entidad mapeada con status tipado', () async {
      final container = containerCon(
        StubReservationsRemoteDatasource(detailResponse: detalle),
      );

      final reserva = await container.read(
        reservationDetailProvider('res-1').future,
      );

      expect(reserva.id, 'res-1');
      expect(reserva.status, ReservationStatus.completed);
      expect(reserva.publicationTitle, 'Cancha');
    });

    test('error del repositorio -> AsyncError', () async {
      final container = containerCon(
        StubReservationsRemoteDatasource(
          error: ServerException(code: 'NOT_FOUND', message: 'no existe'),
        ),
      );

      await expectLater(
        container.read(reservationDetailProvider('res-1').future),
        throwsA(isA<ServerException>()),
      );
      expect(
        container.read(reservationDetailProvider('res-1')).hasError,
        isTrue,
      );
    });
  });
}
