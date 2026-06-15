import '../entities/reservation.dart';

abstract interface class ReservationsRepository {
  Future<Reservation> createReservation({
    required String publicationId,
    required String date,
    required String startTime,
    required String endTime,
  });

  Future<List<Reservation>> getMyReservations();

  Future<Reservation> updateReservationStatus({
    required String id,
    required ReservationStatus status,
  });

  Future<void> cancelReservation({required String id});

  /// Stub: endpoint no implementado en el backend.
  Future<List<Reservation>> getReceivedReservations();

  /// Stub: endpoint no implementado en el backend.
  Future<Reservation> getReservationDetail({required String id});
}
