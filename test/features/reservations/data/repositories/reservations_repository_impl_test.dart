// PI-RES-01 / PI-RES-03 (cadena completa) — Repositorio + datasource real +
// Dio con interceptor de errores: la respuesta del contrato termina en una
// entidad Reservation de dominio con su status tipado.

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:sire/core/network/api_constants.dart';
import 'package:sire/core/network/app_exception.dart';
import 'package:sire/core/network/dio_client.dart';
import 'package:sire/features/reservations/data/datasources/reservations_remote_datasource_real_impl.dart';
import 'package:sire/features/reservations/data/repositories/reservations_repository_impl.dart';
import 'package:sire/features/reservations/domain/entities/reservation.dart';

import '../../../../helpers/fixtures.dart';

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late ReservationsRepositoryImpl repository;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
    adapter = DioAdapter(dio: dio);
    dio.interceptors.add(ErrorInterceptor());
    repository = ReservationsRepositoryImpl(
      remoteDatasource: ReservationsRemoteDatasourceRealImpl(dio: dio),
    );
  });

  test(
    'crear reserva → entidad de dominio con status tipado (PI-RES-01)',
    () async {
      adapter.onPost(
        ApiConstants.reservations,
        (server) => server.reply(201, {
          'message': 'Reserva creada exitosamente',
          'data': reservationJson(withPublication: false),
        }),
        data: Matchers.any,
      );

      final reservation = await repository.createReservation(
        publicationId: 'pub-1',
        date: '2026-06-20',
        startTime: '10:00',
        endTime: '11:00',
      );

      expect(reservation, isA<Reservation>());
      expect(reservation.status, ReservationStatus.pending);
      expect(
        reservation.publicationTitle,
        isNull,
        reason: 'POST no incluye el include de publication',
      );
    },
  );

  test(
    'mis reservas → entidades con status tipado e include mapeado',
    () async {
      adapter.onGet(
        ApiConstants.reservationsMine,
        (server) => server.reply(200, {
          'data': [
            reservationJson(),
            reservationJson(id: 'res-2', status: 'cancelled'),
          ],
        }),
      );

      final reservations = await repository.getMyReservations();

      expect(reservations.length, 2);
      expect(reservations.first.status, ReservationStatus.pending);
      expect(reservations.first.publicationTitle, 'Cancha Los Alerces');
      expect(reservations.last.status, ReservationStatus.cancelled);
    },
  );

  test('actualizar estado → entidad con status tipado', () async {
    adapter.onPatch(
      ApiConstants.reservationStatus('res-1'),
      (server) => server.reply(200, {
        'message': 'Estado actualizado',
        'data': reservationJson(status: 'rejected', withPublication: false),
      }),
      data: Matchers.any,
    );

    final reservation = await repository.updateReservationStatus(
      id: 'res-1',
      status: ReservationStatus.rejected,
    );

    expect(reservation.status, ReservationStatus.rejected);
  });

  test('cancelar reserva → completa sin lanzar', () async {
    adapter.onPatch(
      ApiConstants.reservationCancel('res-1'),
      (server) => server.reply(200, {
        'message': 'Reserva cancelada exitosamente',
        'data': reservationJson(status: 'cancelled', withPublication: false),
      }),
    );

    await expectLater(repository.cancelReservation(id: 'res-1'), completes);
  });

  test('404 en updateStatus → NotFoundException tipada', () async {
    adapter.onPatch(
      ApiConstants.reservationStatus('fantasma'),
      (server) =>
          server.reply(404, errorBody('NOT_FOUND', 'Reserva no encontrada')),
      data: Matchers.any,
    );

    try {
      await repository.updateReservationStatus(
        id: 'fantasma',
        status: ReservationStatus.completed,
      );
      fail('Se esperaba un DioException');
    } on DioException catch (e) {
      expect(e.error, isA<NotFoundException>());
    }
  });

  test('403 en updateStatus → ServerException FORBIDDEN', () async {
    adapter.onPatch(
      ApiConstants.reservationStatus('res-1'),
      (server) => server.reply(
        403,
        errorBody('FORBIDDEN', 'Solo el dueño puede cambiar el estado'),
      ),
      data: Matchers.any,
    );

    try {
      await repository.updateReservationStatus(
        id: 'res-1',
        status: ReservationStatus.completed,
      );
      fail('Se esperaba un DioException');
    } on DioException catch (e) {
      expect(e.error, isA<ServerException>());
      expect((e.error as ServerException).code, 'FORBIDDEN');
    }
  });

  test('getReceivedReservations lanza ServerException desde el stub', () async {
    try {
      await repository.getReceivedReservations();
      fail('Se esperaba una excepción');
    } on ServerException catch (e) {
      expect(e.code, 'ENDPOINT_NOT_AVAILABLE');
    }
  });

  test('getReservationDetail lanza ServerException desde el stub', () async {
    try {
      await repository.getReservationDetail(id: 'res-1');
      fail('Se esperaba una excepción');
    } on ServerException catch (e) {
      expect(e.code, 'ENDPOINT_NOT_AVAILABLE');
    }
  });
}
