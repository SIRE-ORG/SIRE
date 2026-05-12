import '../models/create_publication_request_model.dart';
import '../models/publication_detail_model.dart';
import '../models/publication_summary_item_model.dart';
import '../models/update_publication_request_model.dart';
import 'publications_remote_datasource.dart';

class PublicationsRemoteDatasourceMockImpl
    implements PublicationsRemoteDatasource {
  PublicationsRemoteDatasourceMockImpl();

  static const _availability = AvailabilityConfigModel(
    slotDurationMinutes: 60,
    sameScheduleAllDays: true,
    defaultSchedules: [DayScheduleModel(startTime: '09:00', endTime: '18:00')],
    dayOverrides: [
      DayOverrideModel(dayOfWeek: 'SUNDAY', isClosed: true, schedules: []),
    ],
  );

  static final _seedDetails = <String, PublicationDetailModel>{
    'mock-pub-1': const PublicationDetailModel(
      id: 'mock-pub-1',
      title: 'Cancha de fútbol El Estadio',
      description: 'Cancha de pasto sintético, vestidores y luz nocturna.',
      imageUrl: null,
      region: 'Región de La Araucanía',
      city: 'Temuco',
      category: 'DEPORTE',
      ownerId: 'mock-owner-1',
      ownerName: 'Pedro González',
      rating: null,
      isActive: true,
      availability: _availability,
      createdAt: '2026-05-08T12:00:00Z',
    ),
    'mock-pub-2': const PublicationDetailModel(
      id: 'mock-pub-2',
      title: 'Clases de yoga Namaste',
      description: 'Clases grupales de yoga matinal en parque central.',
      imageUrl: null,
      region: 'Región de La Araucanía',
      city: 'Temuco',
      category: 'RECREACION',
      ownerId: 'mock-user-id-123',
      ownerName: 'Usuario Demo',
      rating: null,
      isActive: true,
      availability: _availability,
      createdAt: '2026-05-09T09:30:00Z',
    ),
    'mock-pub-3': const PublicationDetailModel(
      id: 'mock-pub-3',
      title: 'Restaurante La Pampa',
      description: 'Reserva de mesa para almuerzo o cena.',
      imageUrl: null,
      region: 'Región de La Araucanía',
      city: 'Padre Las Casas',
      category: 'OTROS',
      ownerId: 'mock-user-id-123',
      ownerName: 'Usuario Demo',
      rating: null,
      isActive: false,
      availability: _availability,
      createdAt: '2026-05-09T18:00:00Z',
    ),
  };

  @override
  Future<PublicationDetailModel> getPublicationDetail({
    required String id,
  }) async {
    return _seedDetails[id] ?? _seedDetails.values.first;
  }

  @override
  Future<MyPublicationsResponse> getMyPublications({
    int page = 1,
    int limit = 20,
  }) async {
    if (page > 1) {
      return const MyPublicationsResponse(
        items: [],
        page: 1,
        limit: 20,
        total: 2,
        hasMore: false,
      );
    }
    final mine = _seedDetails.values
        .where((p) => p.ownerId == 'mock-user-id-123')
        .map(
          (p) => PublicationSummaryItemModel(
            id: p.id,
            title: p.title,
            imageUrl: p.imageUrl,
            category: p.category,
            region: p.region,
            isActive: p.isActive,
            createdAt: p.createdAt,
          ),
        )
        .toList();
    return MyPublicationsResponse(
      items: mine,
      page: 1,
      limit: limit,
      total: mine.length,
      hasMore: false,
    );
  }

  @override
  Future<PublicationDetailModel> createPublication({
    required CreatePublicationRequestModel body,
  }) async {
    return PublicationDetailModel(
      id: 'mock-pub-${DateTime.now().millisecondsSinceEpoch}',
      title: body.title,
      description: body.description,
      imageUrl: body.imageUrl,
      region: body.region,
      city: body.city,
      category: body.category.name,
      ownerId: 'mock-user-id-123',
      ownerName: 'Usuario Demo',
      rating: null,
      isActive: true,
      availability: AvailabilityConfigModel.fromEntity(body.availability),
      createdAt: DateTime.now().toUtc().toIso8601String(),
    );
  }

  @override
  Future<PublicationDetailModel> updatePublication({
    required String id,
    required UpdatePublicationRequestModel body,
  }) async {
    final existing = _seedDetails[id] ?? _seedDetails.values.first;
    return PublicationDetailModel(
      id: existing.id,
      title: body.title ?? existing.title,
      description: body.description ?? existing.description,
      imageUrl: body.imageUrl ?? existing.imageUrl,
      region: body.region ?? existing.region,
      city: body.city ?? existing.city,
      category: body.category?.name ?? existing.category,
      ownerId: existing.ownerId,
      ownerName: existing.ownerName,
      rating: existing.rating,
      isActive: existing.isActive,
      availability: body.availability != null
          ? AvailabilityConfigModel.fromEntity(body.availability!)
          : existing.availability,
      createdAt: existing.createdAt,
    );
  }

  @override
  Future<void> togglePublicationStatus({
    required String id,
    required bool isActive,
  }) async {}

  @override
  Future<void> deletePublication({required String id}) async {}
}
