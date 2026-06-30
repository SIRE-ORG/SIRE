import 'package:dio/dio.dart';

import '../../../../core/network/api_constants.dart';
import '../models/create_reservation_request_model.dart';
import '../models/reservation_model.dart';
import 'reservations_remote_datasource.dart';

/// Implementación real de [ReservationsRemoteDatasource] contra el backend.
///
/// La identidad (x-user-id) la inyecta el [AuthInterceptor] de [DioClient];
/// no se necesita [SupabaseClient] en este datasource.
class ReservationsRemoteDatasourceRealImpl
    implements ReservationsRemoteDatasource {
  const ReservationsRemoteDatasourceRealImpl({required this.dio});

  final Dio dio;

  @override
  Future<ReservationModel> createReservation({
    required CreateReservationRequestModel body,
  }) async {
    final response = await dio.post(
      ApiConstants.reservations,
      data: body.toJson(),
    );
    final json =
        (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return ReservationModel.fromJson(json);
  }

  @override
  Future<List<ReservationModel>> getMyReservations() async {
    final response = await dio.get(ApiConstants.reservationsMine);
    final raw =
        ((response.data as Map<String, dynamic>)['data'] as List?) ?? [];
    return raw
        .cast<Map<String, dynamic>>()
        .map(ReservationModel.fromJson)
        .toList();
  }

  @override
  Future<ReservationModel> updateReservationStatus({
    required String id,
    required String status,
  }) async {
    final response = await dio.patch(
      ApiConstants.reservationStatus(id),
      data: {'status': status},
    );
    final json =
        (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return ReservationModel.fromJson(json);
  }

  @override
  Future<ReservationModel> cancelReservation({required String id}) async {
    final response = await dio.patch(ApiConstants.reservationCancel(id));
    final json =
        (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return ReservationModel.fromJson(json);
  }

  @override
  Future<List<ReservationModel>> getReceivedReservations() async {
    final response = await dio.get(ApiConstants.reservationsReceived);
    final raw =
        ((response.data as Map<String, dynamic>)['data'] as List?) ?? [];
    return raw
        .cast<Map<String, dynamic>>()
        .map(ReservationModel.fromJson)
        .toList();
  }

  @override
  Future<ReservationModel> getReservationDetail({required String id}) async {
    final response = await dio.get(ApiConstants.reservationById(id));
    final json =
        (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return ReservationModel.fromJson(json);
  }
}
