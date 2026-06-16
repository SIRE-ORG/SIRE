import 'package:flutter_test/flutter_test.dart';
import 'package:sire/features/reservations/data/datasources/reservations_remote_datasource_mock_impl.dart';
import 'package:sire/features/reservations/data/models/create_reservation_request_model.dart';

void main() {
  late ReservationsRemoteDatasourceMockImpl datasource;

  setUp(() {
    datasource = ReservationsRemoteDatasourceMockImpl();
  });

  group('ReservationsRemoteDatasourceMockImpl', () {
    group('getMyReservations', () {
      test('retorna lista de reservas semilla', () async {
        final results = await datasource.getMyReservations();
        expect(results, isNotEmpty);
        expect(results.length, 2);
      });

      test('las reservas semilla tienen ids esperados', () async {
        final results = await datasource.getMyReservations();
        final ids = results.map((r) => r.id).toList();
        expect(ids, containsAll(['mock-res-1', 'mock-res-2']));
      });

      test('las reservas tienen publicationId correcto', () async {
        final results = await datasource.getMyReservations();
        for (final r in results) {
          expect(r.publicationId, isNotEmpty);
        }
      });
    });

    group('createReservation', () {
      test('crea reserva con datos del request', () async {
        const request = CreateReservationRequestModel(
          publicationId: 'pub-test-1',
          date: '2026-07-10',
          startTime: '09:00',
          endTime: '10:00',
        );

        final result = await datasource.createReservation(body: request);

        expect(result.publicationId, 'pub-test-1');
        expect(result.date, '2026-07-10');
        expect(result.startTime, '09:00');
        expect(result.endTime, '10:00');
        expect(result.status, 'pending');
      });

      test('id generado no es vacío', () async {
        const request = CreateReservationRequestModel(
          publicationId: 'pub-x',
          date: '2026-08-01',
          startTime: '14:00',
          endTime: '15:00',
        );

        final result = await datasource.createReservation(body: request);
        expect(result.id, isNotEmpty);
        expect(result.id, startsWith('mock-res-'));
      });

      test('reserva creada aparece en getMyReservations', () async {
        const request = CreateReservationRequestModel(
          publicationId: 'pub-new',
          date: '2026-09-01',
          startTime: '10:00',
          endTime: '11:00',
        );

        final created = await datasource.createReservation(body: request);
        final all = await datasource.getMyReservations();

        expect(all.any((r) => r.id == created.id), isTrue);
      });
    });

    group('updateReservationStatus', () {
      test('actualiza estado de reserva existente', () async {
        final result = await datasource.updateReservationStatus(
          id: 'mock-res-1',
          status: 'completed',
        );
        expect(result.status, 'completed');
        expect(result.id, 'mock-res-1');
      });

      test('retorna reserva vacía para id inexistente', () async {
        final result = await datasource.updateReservationStatus(
          id: 'no-existe',
          status: 'completed',
        );
        expect(result.id, '');
        expect(result.status, 'pending');
      });

      test('estado cancelado se actualiza correctamente', () async {
        final result = await datasource.updateReservationStatus(
          id: 'mock-res-2',
          status: 'cancelled',
        );
        expect(result.status, 'cancelled');
      });

      test('preserva publicationTitle y publicationCity al actualizar', () async {
        final result = await datasource.updateReservationStatus(
          id: 'mock-res-1',
          status: 'failed',
        );
        expect(result.publicationTitle, 'Cancha de fútbol El Estadio');
        expect(result.publicationCity, 'Temuco');
      });
    });

    group('cancelReservation', () {
      test('cancela reserva existente', () async {
        final result = await datasource.cancelReservation(id: 'mock-res-1');
        expect(result.status, 'cancelled');
        expect(result.id, 'mock-res-1');
      });

      test('retorna reserva vacía para id inexistente', () async {
        final result = await datasource.cancelReservation(id: 'no-existe');
        expect(result.id, '');
        expect(result.status, 'cancelled');
      });

      test('preserva datos de publicación al cancelar', () async {
        final result = await datasource.cancelReservation(id: 'mock-res-2');
        expect(result.publicationTitle, 'Cancha de fútbol El Estadio');
      });
    });

    group('getReceivedReservations', () {
      test('retorna lista de reservas semilla', () async {
        final results = await datasource.getReceivedReservations();
        expect(results, isNotEmpty);
      });

      test('retorna las mismas reservas que getMyReservations', () async {
        final mine = await datasource.getMyReservations();
        final received = await datasource.getReceivedReservations();
        expect(mine.length, received.length);
      });
    });

    group('getReservationDetail', () {
      test('retorna detalle de reserva existente', () async {
        final result = await datasource.getReservationDetail(id: 'mock-res-1');
        expect(result.id, 'mock-res-1');
        expect(result.startTime, '10:00');
      });

      test('retorna primera reserva para id inexistente', () async {
        final result = await datasource.getReservationDetail(id: 'no-existe');
        expect(result.id, isNotEmpty);
      });

      test('retorna detalle de segunda reserva', () async {
        final result = await datasource.getReservationDetail(id: 'mock-res-2');
        expect(result.id, 'mock-res-2');
        expect(result.status, 'completed');
      });
    });
  });
}
