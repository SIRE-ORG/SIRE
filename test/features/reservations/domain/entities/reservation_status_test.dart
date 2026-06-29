// Pruebas de ida y vuelta del enum ReservationStatus y sus helpers.

import 'package:flutter_test/flutter_test.dart';
import 'package:sire/features/reservations/domain/entities/reservation.dart';

void main() {
  group('reservationStatusFromString', () {
    test('mapea los 5 valores del contrato en minúsculas', () {
      expect(reservationStatusFromString('pending'), ReservationStatus.pending);
      expect(
        reservationStatusFromString('cancelled'),
        ReservationStatus.cancelled,
      );
      expect(
        reservationStatusFromString('rejected'),
        ReservationStatus.rejected,
      );
      expect(
        reservationStatusFromString('completed'),
        ReservationStatus.completed,
      );
      expect(reservationStatusFromString('failed'), ReservationStatus.failed);
    });

    test('valor desconocido → pending (default documentado)', () {
      expect(
        reservationStatusFromString('inventado'),
        ReservationStatus.pending,
      );
      expect(reservationStatusFromString(''), ReservationStatus.pending);
    });

    test('case-insensitive', () {
      expect(reservationStatusFromString('PENDING'), ReservationStatus.pending);
      expect(
        reservationStatusFromString('Completed'),
        ReservationStatus.completed,
      );
    });
  });

  group('reservationStatusToString', () {
    test('devuelve el valor en minúsculas para cada enum', () {
      expect(reservationStatusToString(ReservationStatus.pending), 'pending');
      expect(
        reservationStatusToString(ReservationStatus.cancelled),
        'cancelled',
      );
      expect(reservationStatusToString(ReservationStatus.rejected), 'rejected');
      expect(
        reservationStatusToString(ReservationStatus.completed),
        'completed',
      );
      expect(reservationStatusToString(ReservationStatus.failed), 'failed');
    });

    test('ida y vuelta: todos los valores son estables', () {
      for (final s in ReservationStatus.values) {
        expect(reservationStatusFromString(reservationStatusToString(s)), s);
      }
    });
  });

  group('Reservation entidad', () {
    test('props incluye los campos planos y de publicación', () {
      const res = Reservation(
        id: 'res-1',
        publicationId: 'pub-1',
        date: '2026-06-20',
        startTime: '10:00',
        endTime: '11:00',
        status: ReservationStatus.pending,
        createdAt: '2026-06-15T12:00:00Z',
        publicationTitle: 'Cancha',
        publicationCity: 'Temuco',
        publicationImageUrl: null,
      );
      expect(res.props.length, 12);
      expect(res.id, 'res-1');
      expect(res.publicationTitle, 'Cancha');
    });
  });
}
