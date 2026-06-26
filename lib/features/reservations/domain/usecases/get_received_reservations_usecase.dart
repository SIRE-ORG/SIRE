import '../entities/reservation.dart';
import '../repositories/reservations_repository.dart';

class GetReceivedReservationsUseCase {
  const GetReceivedReservationsUseCase(this._repository);

  final ReservationsRepository _repository;

  Future<List<Reservation>> call() => _repository.getReceivedReservations();
}
