import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:sire/features/reservations/domain/entities/reservation.dart';
import 'package:sire/features/reservations/domain/repositories/reservations_repository.dart';
import 'package:sire/features/reservations/domain/usecases/cancel_reservation_usecase.dart';
import 'package:sire/features/reservations/domain/usecases/create_reservation_usecase.dart';
import 'package:sire/features/reservations/domain/usecases/update_reservation_status_usecase.dart';

class _MockReservationsRepository extends Mock
    implements ReservationsRepository {}

const _kReservation = Reservation(
  id: 'res-1',
  publicationId: 'pub-1',
  date: '2026-06-20',
  startTime: '10:00',
  endTime: '11:00',
  status: ReservationStatus.pending,
  createdAt: '2026-06-01T00:00:00Z',
);

void main() {
  late _MockReservationsRepository repo;

  setUp(() {
    repo = _MockReservationsRepository();
    registerFallbackValue(ReservationStatus.pending);
  });

  group('CreateReservationUseCase', () {
    test('delega al repositorio con los parámetros correctos', () async {
      when(() => repo.createReservation(
            publicationId: any(named: 'publicationId'),
            date: any(named: 'date'),
            startTime: any(named: 'startTime'),
            endTime: any(named: 'endTime'),
          )).thenAnswer((_) async => _kReservation);

      final result = await CreateReservationUseCase(repo).call(
        params: const CreateReservationParams(
          publicationId: 'pub-1',
          date: '2026-06-20',
          startTime: '10:00',
          endTime: '11:00',
        ),
      );

      expect(result.id, equals('res-1'));
      expect(result.status, equals(ReservationStatus.pending));
    });
  });

  group('CancelReservationUseCase', () {
    test('delega al repositorio con el id correcto', () async {
      when(() => repo.cancelReservation(id: any(named: 'id')))
          .thenAnswer((_) async {});

      await CancelReservationUseCase(repo).call(id: 'res-1');

      verify(() => repo.cancelReservation(id: 'res-1')).called(1);
    });
  });

  group('UpdateReservationStatusUseCase', () {
    test('delega al repositorio y retorna reserva actualizada', () async {
      const updated = Reservation(
        id: 'res-1',
        publicationId: 'pub-1',
        date: '2026-06-20',
        startTime: '10:00',
        endTime: '11:00',
        status: ReservationStatus.completed,
        createdAt: '2026-06-01T00:00:00Z',
      );
      when(() => repo.updateReservationStatus(
            id: any(named: 'id'),
            status: any(named: 'status'),
          )).thenAnswer((_) async => updated);

      final result = await UpdateReservationStatusUseCase(repo).call(
        id: 'res-1',
        status: ReservationStatus.completed,
      );

      expect(result.status, equals(ReservationStatus.completed));
    });
  });
}
