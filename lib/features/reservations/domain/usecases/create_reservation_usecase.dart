import '../entities/reservation.dart';
import '../repositories/reservations_repository.dart';

class CreateReservationParams {
  const CreateReservationParams({
    required this.publicationId,
    required this.date,
    required this.startTime,
    required this.endTime,
  });

  final String publicationId;
  final String date;
  final String startTime;
  final String endTime;
}

class CreateReservationUseCase {
  const CreateReservationUseCase(this._repository);

  final ReservationsRepository _repository;

  Future<Reservation> call({required CreateReservationParams params}) =>
      _repository.createReservation(
        publicationId: params.publicationId,
        date: params.date,
        startTime: params.startTime,
        endTime: params.endTime,
      );
}
