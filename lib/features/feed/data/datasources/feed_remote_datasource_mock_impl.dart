import '../models/feed_response_model.dart';
import '../models/publication_summary_model.dart';
import 'feed_remote_datasource.dart';

class FeedRemoteDatasourceMockImpl implements FeedRemoteDatasource {
  const FeedRemoteDatasourceMockImpl();

  static const _seed = <PublicationSummaryModel>[
    PublicationSummaryModel(
      id: 'mock-pub-1',
      title: 'Cancha de fútbol El Estadio',
      description: 'Cancha de pasto sintético, vestidores y luz nocturna.',
      imageUrl: null,
      region: 'Región de La Araucanía',
      city: 'Temuco',
      category: 'DEPORTE',
      ownerName: 'Pedro González',
      ownerId: 'mock-owner-1',
      rating: null,
      createdAt: '2026-05-08T12:00:00Z',
    ),
    PublicationSummaryModel(
      id: 'mock-pub-2',
      title: 'Clases de yoga Namaste',
      description: 'Clases grupales de yoga matinal en parque central.',
      imageUrl: null,
      region: 'Región de La Araucanía',
      city: 'Temuco',
      category: 'RECREACION',
      ownerName: 'Usuario Demo',
      ownerId: 'mock-user-id-123',
      rating: 4.8,
      createdAt: '2026-05-09T09:30:00Z',
    ),
    PublicationSummaryModel(
      id: 'mock-pub-3',
      title: 'Restaurante La Pampa',
      description: 'Reserva de mesa para almuerzo o cena.',
      imageUrl: null,
      region: 'Región de La Araucanía',
      city: 'Padre Las Casas',
      category: 'OTROS',
      ownerName: 'Usuario Demo',
      ownerId: 'mock-user-id-123',
      rating: 4.2,
      createdAt: '2026-05-09T18:00:00Z',
    ),
    PublicationSummaryModel(
      id: 'mock-pub-4',
      title: 'Taller de pintura para niños',
      description: 'Talleres semanales de arte y manualidades.',
      imageUrl: null,
      region: 'Región de La Araucanía',
      city: 'Villarrica',
      category: 'RECREACION',
      ownerName: 'María Soto',
      ownerId: 'mock-owner-2',
      rating: null,
      createdAt: '2026-05-09T20:00:00Z',
    ),
    PublicationSummaryModel(
      id: 'mock-pub-5',
      title: 'Cine al aire libre',
      description: 'Función de películas chilenas en plaza Aníbal Pinto.',
      imageUrl: null,
      region: 'Región de La Araucanía',
      city: 'Temuco',
      category: 'EVENTOS',
      ownerName: 'Centro Cultural',
      ownerId: 'mock-owner-3',
      rating: null,
      createdAt: '2026-05-10T08:00:00Z',
    ),
  ];

  @override
  Future<FeedResponseModel> getFeed({
    required String region,
    String? city,
    String? order,
    String? category,
    int page = 1,
    int limit = 20,
  }) async {
    if (page > 1) {
      return FeedResponseModel(
        items: const [],
        page: page,
        limit: limit,
        total: _seed.length,
        hasMore: false,
      );
    }
    final filtered = _seed
        .where((p) => category == null || p.category == category)
        .toList();
    return FeedResponseModel(
      items: filtered,
      page: 1,
      limit: limit,
      total: filtered.length,
      hasMore: false,
    );
  }
}
