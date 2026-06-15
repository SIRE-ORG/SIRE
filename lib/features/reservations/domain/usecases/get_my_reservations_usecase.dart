import '../entities/reservation.dart';
import '../repositories/reservations_repository.dart';

class GetMyReservationsUseCase {
  const GetMyReservationsUseCase(this._repository);

  final ReservationsRepository _repository;

  Future<List<Reservation>> call() => _repository.getMyReservations();
}
