import '../entities/reservation.dart';
import '../repositories/reservations_repository.dart';

class GetReservationDetailUseCase {
  const GetReservationDetailUseCase(this._repository);

  final ReservationsRepository _repository;

  Future<Reservation> call({required String id}) =>
      _repository.getReservationDetail(id: id);
}
