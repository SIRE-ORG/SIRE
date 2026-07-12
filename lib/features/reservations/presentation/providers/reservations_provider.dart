import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/api_flags.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/reservations_remote_datasource.dart';
import '../../data/datasources/reservations_remote_datasource_mock_impl.dart';
import '../../data/datasources/reservations_remote_datasource_real_impl.dart';
import '../../data/repositories/reservations_repository_impl.dart';
import '../../domain/entities/reservation.dart';
import '../../domain/repositories/reservations_repository.dart';
import '../../domain/usecases/cancel_reservation_usecase.dart';
import '../../domain/usecases/create_reservation_usecase.dart';
import '../../domain/usecases/get_my_reservations_usecase.dart';
import '../../domain/usecases/get_received_reservations_usecase.dart';
import '../../domain/usecases/get_reservation_detail_usecase.dart';
import '../../domain/usecases/update_reservation_status_usecase.dart';

part 'reservations_provider.g.dart';

// ---------------------------------------------------------------------------
// Infraestructura
// ---------------------------------------------------------------------------

@riverpod
ReservationsRemoteDatasource reservationsRemoteDatasource(Ref ref) =>
    ApiFlags.useMocks
    ? ReservationsRemoteDatasourceMockImpl()
    : ReservationsRemoteDatasourceRealImpl(dio: DioClient.createSync().dio);

@riverpod
ReservationsRepository reservationsRepository(Ref ref) =>
    ReservationsRepositoryImpl(
      remoteDatasource: ref.watch(reservationsRemoteDatasourceProvider),
    );

// ---------------------------------------------------------------------------
// ReceivedReservationsNotifier - reservas recibidas por el publicador
// ---------------------------------------------------------------------------

@riverpod
Future<List<Reservation>> receivedReservations(Ref ref) =>
    GetReceivedReservationsUseCase(
      ref.read(reservationsRepositoryProvider),
    ).call();

// ---------------------------------------------------------------------------
// ReservationDetail - detalle de una reserva por id
// ---------------------------------------------------------------------------

@riverpod
Future<Reservation> reservationDetail(Ref ref, String id) =>
    GetReservationDetailUseCase(
      ref.read(reservationsRepositoryProvider),
    ).call(id: id);

// ---------------------------------------------------------------------------
// MyReservationsNotifier - listado de reservas del solicitante
// ---------------------------------------------------------------------------

@riverpod
class MyReservationsNotifier extends _$MyReservationsNotifier {
  @override
  Future<List<Reservation>> build() async {
    return GetMyReservationsUseCase(
      ref.read(reservationsRepositoryProvider),
    ).call();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

// ---------------------------------------------------------------------------
// ReceivedReservationsNotifier - reservas recibidas sobre las publicaciones
// del dueño (lado publisher). Espejo de MyReservationsNotifier.
// ---------------------------------------------------------------------------

@riverpod
class ReceivedReservationsNotifier extends _$ReceivedReservationsNotifier {
  @override
  Future<List<Reservation>> build() async {
    return GetReceivedReservationsUseCase(
      ref.read(reservationsRepositoryProvider),
    ).call();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

// ---------------------------------------------------------------------------
// ReservationActionNotifier - create / updateStatus / cancel
// ---------------------------------------------------------------------------

@riverpod
class ReservationActionNotifier extends _$ReservationActionNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<Reservation> create({required CreateReservationParams params}) async {
    state = const AsyncLoading();
    try {
      final result = await CreateReservationUseCase(
        ref.read(reservationsRepositoryProvider),
      ).call(params: params);
      state = const AsyncData(null);
      ref.invalidate(myReservationsNotifierProvider);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<Reservation> updateStatus({
    required String id,
    required ReservationStatus status,
  }) async {
    state = const AsyncLoading();
    try {
      final result = await UpdateReservationStatusUseCase(
        ref.read(reservationsRepositoryProvider),
      ).call(id: id, status: status);
      state = const AsyncData(null);
      // updateStatus (aceptar/rechazar) lo ejecuta el dueño de la publicación
      // sobre una reserva recibida -> refresca la lista de recibidas.
      ref.invalidate(receivedReservationsNotifierProvider);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> cancel({required String id}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => CancelReservationUseCase(
        ref.read(reservationsRepositoryProvider),
      ).call(id: id),
    );
    ref.invalidate(myReservationsNotifierProvider);
  }
}
