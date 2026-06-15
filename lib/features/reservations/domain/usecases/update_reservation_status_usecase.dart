import '../entities/reservation.dart';
import '../repositories/reservations_repository.dart';

class UpdateReservationStatusUseCase {
  const UpdateReservationStatusUseCase(this._repository);

  final ReservationsRepository _repository;

  Future<Reservation> call({
    required String id,
    required ReservationStatus status,
  }) => _repository.updateReservationStatus(id: id, status: status);
}
