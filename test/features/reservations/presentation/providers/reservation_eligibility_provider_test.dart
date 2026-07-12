// PI-PROV-ELEGIBILIDAD - reservationEligibilityProvider deriva los 4 estados
// de la regla de negocio 4 (flujo de 3 fases ANON -> GUEST -> ACTIVE) a partir
// de authStatusProvider y (solo para guest) de las reservas propias.
//
// Se overridea authStatusProvider directamente (sin montar toda la cadena de
// currentProfile/authRepository) para mantener el test aislado, tal como
// permite el diseño del provider.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sire/features/auth/domain/entities/user_profile.dart';
import 'package:sire/features/auth/presentation/providers/auth_provider.dart';
import 'package:sire/features/reservations/domain/entities/reservation.dart';
import 'package:sire/features/reservations/domain/entities/reservation_eligibility.dart';
import 'package:sire/features/reservations/domain/repositories/reservations_repository.dart';
import 'package:sire/features/reservations/presentation/providers/reservation_eligibility_provider.dart';
import 'package:sire/features/reservations/presentation/providers/reservations_provider.dart';

class MockReservationsRepository extends Mock
    implements ReservationsRepository {}

const _unaReserva = Reservation(
  id: 'r1',
  publicationId: 'pub-1',
  date: '2026-06-20',
  startTime: '10:00',
  endTime: '11:00',
  status: ReservationStatus.pending,
  createdAt: '2026-06-15T12:00:00Z',
);

void main() {
  late MockReservationsRepository repo;

  setUp(() {
    repo = MockReservationsRepository();
  });

  ProviderContainer buildContainer({required AccountStatus? status}) {
    final container = ProviderContainer(
      overrides: [
        authStatusProvider.overrideWith((ref) async => status),
        reservationsRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('sin sesión (status null) -> needsGuestForm', () async {
    final container = buildContainer(status: null);

    final result = await container.read(reservationEligibilityProvider.future);

    expect(result, ReservationEligibility.needsGuestForm);
    verifyNever(() => repo.getMyReservations());
  });

  test('status anon -> needsGuestForm', () async {
    final container = buildContainer(status: AccountStatus.anon);

    final result = await container.read(reservationEligibilityProvider.future);

    expect(result, ReservationEligibility.needsGuestForm);
    verifyNever(() => repo.getMyReservations());
  });

  test('status active -> allowed (sin consultar reservas)', () async {
    final container = buildContainer(status: AccountStatus.active);

    final result = await container.read(reservationEligibilityProvider.future);

    expect(result, ReservationEligibility.allowed);
    verifyNever(() => repo.getMyReservations());
  });

  test('status guest con 0 reservas -> allowedExistingProfile', () async {
    when(() => repo.getMyReservations()).thenAnswer((_) async => []);

    final container = buildContainer(status: AccountStatus.guest);

    final result = await container.read(reservationEligibilityProvider.future);

    expect(result, ReservationEligibility.allowedExistingProfile);
  });

  test('status guest con ≥1 reserva -> needsActivation', () async {
    when(() => repo.getMyReservations()).thenAnswer((_) async => [_unaReserva]);

    final container = buildContainer(status: AccountStatus.guest);

    final result = await container.read(reservationEligibilityProvider.future);

    expect(result, ReservationEligibility.needsActivation);
  });
}
