// PI-RES-01 / PI-RES-03 (parte a) - Integración de la fuente de datos real
// de reservas contra HTTP simulado con la forma exacta del contrato del
// backend (H9: POST usa date/startTime/endTime, no slotId).

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:sire/core/network/api_constants.dart';
import 'package:sire/core/network/app_exception.dart';
import 'package:sire/core/network/dio_client.dart';
import 'package:sire/features/reservations/data/datasources/reservations_remote_datasource_real_impl.dart';
import 'package:sire/features/reservations/data/models/create_reservation_request_model.dart';

import '../../../../helpers/fixtures.dart';

const _solicitudCreacion = CreateReservationRequestModel(
  publicationId: 'pub-1',
  date: '2026-06-20',
  startTime: '10:00',
  endTime: '11:00',
);

void main() {
  late Dio dio;
  late DioAdapter adapter;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
    adapter = DioAdapter(dio: dio);
    dio.interceptors.add(ErrorInterceptor());
  });

  ReservationsRemoteDatasourceRealImpl datasourceCon() =>
      ReservationsRemoteDatasourceRealImpl(dio: dio);

  group('createReservation (PI-RES-01)', () {
    test('201 del contrato -> modelo con status pending, body exacto sin '
        'slotId', () async {
      final payloadEsperado = {
        'publicationId': 'pub-1',
        'date': '2026-06-20',
        'startTime': '10:00',
        'endTime': '11:00',
      };
      adapter.onPost(
        ApiConstants.reservations,
        (server) => server.reply(201, {
          'message': 'Reserva creada exitosamente',
          'data': reservationJson(withPublication: false),
        }),
        data: payloadEsperado,
      );

      final model = await datasourceCon().createReservation(
        body: _solicitudCreacion,
      );

      expect(model.id, 'res-1');
      expect(model.status, 'pending');
      expect(
        model.publicationTitle,
        isNull,
        reason: 'POST no incluye el include de publication',
      );
    });

    test('400 ValidationException cuando falta un campo', () async {
      adapter.onPost(
        ApiConstants.reservations,
        (server) => server.reply(
          400,
          errorBody('VALIDATION_ERROR', 'date es obligatorio'),
        ),
        data: Matchers.any,
      );

      try {
        await datasourceCon().createReservation(body: _solicitudCreacion);
        fail('Se esperaba un DioException');
      } on DioException catch (e) {
        expect(e.error, isA<ValidationException>());
      }
    });
  });

  group('getMyReservations', () {
    test(
      '200 -> lista con publication.title/city/imageUrl aplanados',
      () async {
        adapter.onGet(
          ApiConstants.reservationsMine,
          (server) => server.reply(200, {
            'data': [
              reservationJson(),
              reservationJson(
                id: 'res-2',
                status: 'completed',
                withPublication: true,
              ),
            ],
          }),
        );

        final models = await datasourceCon().getMyReservations();

        expect(models.length, 2);
        expect(models.first.publicationTitle, 'Cancha Los Alerces');
        expect(models.first.publicationCity, 'Temuco');
        expect(models.first.status, 'pending');
        expect(models.last.status, 'completed');
      },
    );

    test('401 sin header de identidad', () async {
      adapter.onGet(
        ApiConstants.reservationsMine,
        (server) =>
            server.reply(401, errorBody('UNAUTHORIZED', 'Falta identidad')),
      );

      try {
        await datasourceCon().getMyReservations();
        fail('Se esperaba un DioException');
      } on DioException catch (e) {
        expect(e.error, isA<UnauthorizedException>());
      }
    });
  });

  group('updateReservationStatus', () {
    test('PATCH con {status} -> modelo actualizado', () async {
      adapter.onPatch(
        ApiConstants.reservationStatus('res-1'),
        (server) => server.reply(200, {
          'message': 'Estado actualizado',
          'data': reservationJson(status: 'completed', withPublication: false),
        }),
        data: {'status': 'completed'},
      );

      final model = await datasourceCon().updateReservationStatus(
        id: 'res-1',
        status: 'completed',
      );

      expect(model.status, 'completed');
    });

    test('404 NOT_FOUND -> NotFoundException', () async {
      adapter.onPatch(
        ApiConstants.reservationStatus('no-existe'),
        (server) =>
            server.reply(404, errorBody('NOT_FOUND', 'Reserva no encontrada')),
        data: Matchers.any,
      );

      try {
        await datasourceCon().updateReservationStatus(
          id: 'no-existe',
          status: 'completed',
        );
        fail('Se esperaba un DioException');
      } on DioException catch (e) {
        expect(e.error, isA<NotFoundException>());
        expect((e.error as NotFoundException).code, 'NOT_FOUND');
      }
    });

    test('403 FORBIDDEN (no es dueño) -> ServerException', () async {
      adapter.onPatch(
        ApiConstants.reservationStatus('res-1'),
        (server) => server.reply(
          403,
          errorBody('FORBIDDEN', 'Solo el dueño puede cambiar el estado'),
        ),
        data: Matchers.any,
      );

      try {
        await datasourceCon().updateReservationStatus(
          id: 'res-1',
          status: 'rejected',
        );
        fail('Se esperaba un DioException');
      } on DioException catch (e) {
        expect(e.error, isA<ServerException>());
        expect((e.error as ServerException).code, 'FORBIDDEN');
      }
    });

    test('400 status fuera del enum -> ValidationException', () async {
      adapter.onPatch(
        ApiConstants.reservationStatus('res-1'),
        (server) => server.reply(
          400,
          errorBody('VALIDATION_ERROR', 'El estado proporcionado no es válido'),
        ),
        data: Matchers.any,
      );

      try {
        await datasourceCon().updateReservationStatus(
          id: 'res-1',
          status: 'inventado',
        );
        fail('Se esperaba un DioException');
      } on DioException catch (e) {
        expect(e.error, isA<ValidationException>());
      }
    });
  });

  group('cancelReservation', () {
    test('PATCH reservationCancel(id) simulado 200 -> completa', () async {
      adapter.onPatch(
        ApiConstants.reservationCancel('res-1'),
        (server) => server.reply(200, {
          'message': 'Reserva cancelada exitosamente',
          'data': reservationJson(status: 'cancelled', withPublication: false),
        }),
      );

      final model = await datasourceCon().cancelReservation(id: 'res-1');

      expect(model.status, 'cancelled');
    });

    test(
      '404 actual por H8 - el mock reproduce el comportamiento actual',
      () async {
        adapter.onPatch(
          ApiConstants.reservationCancel('no-existe'),
          (server) =>
              server.reply(404, errorBody('NOT_FOUND', 'Ruta no encontrada')),
        );

        try {
          await datasourceCon().cancelReservation(id: 'no-existe');
          fail('Se esperaba un DioException');
        } on DioException catch (e) {
          expect(e.error, isA<NotFoundException>());
        }
      },
    );
  });

  group('getReceivedReservations y getReservationDetail', () {
    test(
      'getReceivedReservations 200 -> lista de modelos con applicant',
      () async {
        adapter.onGet(
          ApiConstants.reservationsReceived,
          (server) => server.reply(200, {
            'data': [
              {
                ...reservationJson(id: 'recv-1', status: 'pending'),
                'applicant': {'name': 'Carlos Pérez', 'email': 'c@mail.com'},
              },
            ],
          }),
        );

        final results = await datasourceCon().getReceivedReservations();
        expect(results, hasLength(1));
        expect(results.first.id, 'recv-1');
        expect(results.first.applicantName, 'Carlos Pérez');
      },
    );

    test('getReservationDetail 200 -> modelo con id correcto', () async {
      adapter.onGet(
        ApiConstants.reservationById('res-1'),
        (server) => server.reply(200, {
          'data': reservationJson(id: 'res-1', status: 'pending'),
        }),
      );

      final result = await datasourceCon().getReservationDetail(id: 'res-1');
      expect(result.id, 'res-1');
      expect(result.status, 'pending');
    });
  });
}
