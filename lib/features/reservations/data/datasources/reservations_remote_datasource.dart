import '../models/create_reservation_request_model.dart';
import '../models/reservation_model.dart';

abstract interface class ReservationsRemoteDatasource {
  Future<ReservationModel> createReservation({
    required CreateReservationRequestModel body,
  });

  Future<List<ReservationModel>> getMyReservations();

  Future<ReservationModel> updateReservationStatus({
    required String id,
    required String status,
  });

  Future<ReservationModel> cancelReservation({required String id});

  /// Stub: endpoint no implementado en el backend.
  Future<List<ReservationModel>> getReceivedReservations();

  /// Stub: endpoint no implementado en el backend.
  Future<ReservationModel> getReservationDetail({required String id});
}
