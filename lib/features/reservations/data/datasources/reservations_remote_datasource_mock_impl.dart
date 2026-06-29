import '../models/create_reservation_request_model.dart';
import '../models/reservation_model.dart';
import 'reservations_remote_datasource.dart';

class ReservationsRemoteDatasourceMockImpl
    implements ReservationsRemoteDatasource {
  ReservationsRemoteDatasourceMockImpl();

  final _seed = <String, ReservationModel>{
    'mock-res-1': const ReservationModel(
      id: 'mock-res-1',
      publicationId: 'mock-pub-1',
      date: '2026-06-20',
      startTime: '10:00',
      endTime: '11:00',
      status: 'pending',
      createdAt: '2026-06-15T12:00:00Z',
      publicationTitle: 'Cancha de fútbol El Estadio',
      publicationCity: 'Temuco',
      publicationImageUrl: null,
    ),
    'mock-res-2': const ReservationModel(
      id: 'mock-res-2',
      publicationId: 'mock-pub-1',
      date: '2026-06-22',
      startTime: '14:00',
      endTime: '15:00',
      status: 'completed',
      createdAt: '2026-06-15T12:00:00Z',
      publicationTitle: 'Cancha de fútbol El Estadio',
      publicationCity: 'Temuco',
      publicationImageUrl: null,
    ),
  };

  // Seed específico para reservas recibidas (lado publicador)
  static const _receivedSeed = [
    ReservationModel(
      id: 'mock-recv-001',
      publicationId: 'mock-pub-1',
      date: 'Jue 15 may',
      startTime: '14:00',
      endTime: '15:00',
      status: 'pending',
      createdAt: '2026-05-14T10:00:00Z',
      publicationTitle: 'Cancha de futbol sintetica',
      applicantName: 'Carlos Pérez',
      applicantEmail: 'carlosperez@mail.com',
    ),
    ReservationModel(
      id: 'mock-recv-002',
      publicationId: 'mock-pub-1',
      date: 'Vie 16 may',
      startTime: '09:00',
      endTime: '10:00',
      status: 'pending',
      createdAt: '2026-05-14T11:00:00Z',
      publicationTitle: 'Cancha de futbol sintetica',
      applicantName: 'Ana Ruiz',
      applicantEmail: 'anaruiz@mail.com',
    ),
    ReservationModel(
      id: 'mock-recv-hist-001',
      publicationId: 'mock-pub-1',
      date: 'Lun 5 may',
      startTime: '10:00',
      endTime: '11:00',
      status: 'completed',
      createdAt: '2026-05-03T09:00:00Z',
      publicationTitle: 'Cancha de futbol sintetica',
      applicantName: 'Pedro Soto',
      applicantEmail: 'pedrosoto@mail.com',
    ),
  ];

  @override
  Future<ReservationModel> createReservation({
    required CreateReservationRequestModel body,
  }) async {
    final model = ReservationModel(
      id: 'mock-res-${DateTime.now().millisecondsSinceEpoch}',
      publicationId: body.publicationId,
      date: body.date,
      startTime: body.startTime,
      endTime: body.endTime,
      status: 'pending',
      createdAt: DateTime.now().toUtc().toIso8601String(),
    );
    _seed[model.id] = model;
    return model;
  }

  @override
  Future<List<ReservationModel>> getMyReservations() async =>
      _seed.values.toList();

  @override
  Future<ReservationModel> updateReservationStatus({
    required String id,
    required String status,
  }) async {
    final existing = _seed[id];
    if (existing == null) {
      return const ReservationModel(
        id: '',
        publicationId: '',
        date: '',
        startTime: '',
        endTime: '',
        status: 'pending',
        createdAt: '',
      );
    }
    final updated = ReservationModel(
      id: existing.id,
      publicationId: existing.publicationId,
      date: existing.date,
      startTime: existing.startTime,
      endTime: existing.endTime,
      status: status,
      createdAt: existing.createdAt,
      publicationTitle: existing.publicationTitle,
      publicationCity: existing.publicationCity,
      publicationImageUrl: existing.publicationImageUrl,
    );
    _seed[id] = updated;
    return updated;
  }

  @override
  Future<ReservationModel> cancelReservation({required String id}) async {
    final existing = _seed[id];
    if (existing == null) {
      return const ReservationModel(
        id: '',
        publicationId: '',
        date: '',
        startTime: '',
        endTime: '',
        status: 'cancelled',
        createdAt: '',
      );
    }
    final updated = ReservationModel(
      id: existing.id,
      publicationId: existing.publicationId,
      date: existing.date,
      startTime: existing.startTime,
      endTime: existing.endTime,
      status: 'cancelled',
      createdAt: existing.createdAt,
      publicationTitle: existing.publicationTitle,
      publicationCity: existing.publicationCity,
      publicationImageUrl: existing.publicationImageUrl,
    );
    _seed[id] = updated;
    return updated;
  }

  @override
  Future<List<ReservationModel>> getReceivedReservations() async =>
      _receivedSeed;

  @override
  Future<ReservationModel> getReservationDetail({required String id}) async =>
      _seed[id] ?? _seed.values.first;
}
