import '../repositories/reservations_repository.dart';

class CancelReservationUseCase {
  const CancelReservationUseCase(this._repository);

  final ReservationsRepository _repository;

  Future<void> call({required String id}) =>
      _repository.cancelReservation(id: id);
}
