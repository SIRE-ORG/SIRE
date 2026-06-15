import '../../domain/entities/reservation.dart';
import '../../domain/repositories/reservations_repository.dart';
import '../datasources/reservations_remote_datasource.dart';
import '../models/create_reservation_request_model.dart';

class ReservationsRepositoryImpl implements ReservationsRepository {
  const ReservationsRepositoryImpl({required this.remoteDatasource});

  final ReservationsRemoteDatasource remoteDatasource;

  @override
  Future<Reservation> createReservation({
    required String publicationId,
    required String date,
    required String startTime,
    required String endTime,
  }) async {
    final body = CreateReservationRequestModel(
      publicationId: publicationId,
      date: date,
      startTime: startTime,
      endTime: endTime,
    );
    final model = await remoteDatasource.createReservation(body: body);
    return model.toEntity();
  }

  @override
  Future<List<Reservation>> getMyReservations() async {
    final models = await remoteDatasource.getMyReservations();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Reservation> updateReservationStatus({
    required String id,
    required ReservationStatus status,
  }) async {
    final model = await remoteDatasource.updateReservationStatus(
      id: id,
      status: reservationStatusToString(status),
    );
    return model.toEntity();
  }

  @override
  Future<void> cancelReservation({required String id}) async {
    await remoteDatasource.cancelReservation(id: id);
  }

  @override
  Future<List<Reservation>> getReceivedReservations() async {
    final models = await remoteDatasource.getReceivedReservations();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Reservation> getReservationDetail({required String id}) async {
    final model = await remoteDatasource.getReservationDetail(id: id);
    return model.toEntity();
  }
}
