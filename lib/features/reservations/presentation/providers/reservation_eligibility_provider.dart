import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../auth/domain/entities/user_profile.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/reservation_eligibility.dart';
import '../../domain/usecases/get_my_reservations_usecase.dart';
import 'reservations_provider.dart';

part 'reservation_eligibility_provider.g.dart';

/// Deriva la [ReservationEligibility] del usuario actual (regla de negocio 4
/// del flujo de 3 fases). Depende de [authStatusProvider] (feature auth) y,
/// solo para el caso `guest`, de las reservas propias.
@riverpod
Future<ReservationEligibility> reservationEligibility(Ref ref) async {
  final status = await ref.watch(authStatusProvider.future);

  if (status == null || status == AccountStatus.anon) {
    return ReservationEligibility.needsGuestForm;
  }
  if (status == AccountStatus.active) {
    return ReservationEligibility.allowed;
  }

  // Único caso restante: AccountStatus.guest. Se distingue por si ya tiene
  // alguna reserva previa (sin importar su estado).
  final reservations = await GetMyReservationsUseCase(
    ref.watch(reservationsRepositoryProvider),
  ).call();
  return reservations.isEmpty
      ? ReservationEligibility.allowedExistingProfile
      : ReservationEligibility.needsActivation;
}
