// Dobles de prueba compartidos: mocks de Supabase (mocktail) y fakes de
// datasources para las pruebas de providers.

import 'package:mocktail/mocktail.dart';
import 'package:sire/features/feed/data/datasources/feed_remote_datasource.dart';
import 'package:sire/features/feed/data/datasources/geo_datasource.dart';
import 'package:sire/features/feed/data/models/feed_response_model.dart';
import 'package:sire/features/feed/domain/entities/geo_location.dart';
import 'package:sire/features/publications/data/datasources/publications_remote_datasource.dart';
import 'package:sire/features/publications/data/models/create_publication_request_model.dart';
import 'package:sire/features/publications/data/models/publication_detail_model.dart';
import 'package:sire/features/publications/data/models/update_publication_request_model.dart';
import 'package:sire/features/reservations/data/datasources/reservations_remote_datasource.dart';
import 'package:sire/features/reservations/data/models/create_reservation_request_model.dart';
import 'package:sire/features/reservations/data/models/reservation_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ---------------------------------------------------------------------------
// Supabase (mocktail)
// ---------------------------------------------------------------------------

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockUser extends Mock implements User {}

class MockSession extends Mock implements Session {}

/// SupabaseClient simulado cuya sesión contiene a [user] (o nadie, si es null).
MockSupabaseClient supabaseWithUser(User? user) {
  final client = MockSupabaseClient();
  final auth = MockGoTrueClient();
  when(() => client.auth).thenReturn(auth);
  when(() => auth.currentUser).thenReturn(user);
  return client;
}

User fakeUser({
  String id = 'user-1',
  String email = 'dani@sire.cl',
  bool emailConfirmed = true,
}) {
  final user = MockUser();
  when(() => user.id).thenReturn(id);
  when(() => user.email).thenReturn(email);
  when(
    () => user.emailConfirmedAt,
  ).thenReturn(emailConfirmed ? '2026-06-01T00:00:00Z' : null);
  return user;
}

Session fakeSession({String userId = 'user-1', String token = 'token-abc'}) {
  final session = MockSession();
  when(() => session.accessToken).thenReturn(token);
  when(() => session.user).thenReturn(fakeUser(id: userId));
  return session;
}

// ---------------------------------------------------------------------------
// Fakes de datasources
// ---------------------------------------------------------------------------

/// GeoDatasource que revienta si alguien lo invoca: en las pruebas donde se
/// monta, la geolocalización no debe participar del flujo.
class UnusedGeoDatasource implements GeoDatasource {
  const UnusedGeoDatasource();

  @override
  Future<GeoLocation> getCurrentLocation() =>
      throw StateError('GeoDatasource no debía ser invocado en esta prueba');
}

/// FeedRemoteDatasource controlable: responde [response] o lanza [error].
class StubFeedRemoteDatasource implements FeedRemoteDatasource {
  const StubFeedRemoteDatasource({this.response, this.error});

  final FeedResponseModel? response;
  final Object? error;

  @override
  Future<FeedResponseModel> getFeed({
    required String region,
    String? city,
    String? order,
    String? category,
    int page = 1,
    int limit = 20,
  }) async {
    if (error != null) throw error!;
    return response!;
  }
}

/// PublicationsRemoteDatasource controlable para pruebas de providers.
/// Solo implementa lo que esas pruebas ejercitan; el resto no debe llamarse.
class StubPublicationsRemoteDatasource implements PublicationsRemoteDatasource {
  const StubPublicationsRemoteDatasource({this.mineResponse, this.error});

  final MyPublicationsResponse? mineResponse;
  final Object? error;

  @override
  Future<MyPublicationsResponse> getMyPublications({
    int page = 1,
    int limit = 20,
  }) async {
    if (error != null) throw error!;
    return mineResponse!;
  }

  @override
  Future<PublicationDetailModel> getPublicationDetail({required String id}) =>
      throw UnimplementedError();

  @override
  Future<PublicationDetailModel> createPublication({
    required CreatePublicationRequestModel body,
  }) => throw UnimplementedError();

  @override
  Future<PublicationDetailModel> updatePublication({
    required String id,
    required UpdatePublicationRequestModel body,
  }) => throw UnimplementedError();

  @override
  Future<void> togglePublicationStatus({
    required String id,
    required bool isActive,
  }) => throw UnimplementedError();

  @override
  Future<void> deletePublication({required String id}) =>
      throw UnimplementedError();
}

// ---------------------------------------------------------------------------
// Reservations — fakes de datasources
// ---------------------------------------------------------------------------

/// ReservationsRemoteDatasource controlable para pruebas de providers.
/// Solo implementa lo que esas pruebas ejercitan; el resto no debe llamarse.
class StubReservationsRemoteDatasource implements ReservationsRemoteDatasource {
  const StubReservationsRemoteDatasource({
    this.myResponse,
    this.receivedResponse,
    this.error,
  });

  final List<ReservationModel>? myResponse;
  final List<ReservationModel>? receivedResponse;
  final Object? error;

  @override
  Future<ReservationModel> createReservation({
    required CreateReservationRequestModel body,
  }) => throw UnimplementedError();

  @override
  Future<List<ReservationModel>> getMyReservations() async {
    if (error != null) throw error!;
    return myResponse!;
  }

  @override
  Future<ReservationModel> updateReservationStatus({
    required String id,
    required String status,
  }) => throw UnimplementedError();

  @override
  Future<ReservationModel> cancelReservation({required String id}) =>
      throw UnimplementedError();

  @override
  Future<List<ReservationModel>> getReceivedReservations() async {
    if (error != null) throw error!;
    return receivedResponse!;
  }

  @override
  Future<ReservationModel> getReservationDetail({required String id}) =>
      throw UnimplementedError();
}
