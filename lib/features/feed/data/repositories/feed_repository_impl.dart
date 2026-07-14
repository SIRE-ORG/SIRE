import '../../../../core/storage/local_storage_service.dart';
import '../../../publications/domain/entities/publication.dart';
import '../../../publications/data/models/publication_detail_model.dart';
import '../../domain/entities/feed_page.dart';
import '../../domain/entities/geo_location.dart';
import '../../domain/repositories/feed_repository.dart';
import '../datasources/feed_remote_datasource.dart';
import '../datasources/geo_datasource.dart';

class FeedRepositoryImpl implements FeedRepository {
  const FeedRepositoryImpl({
    required this.remoteDatasource,
    required this.geoDatasource,
    required this.storage,
  });

  final FeedRemoteDatasource remoteDatasource;
  final GeoDatasource geoDatasource;
  final LocalStorageService storage;

  @override
  Future<FeedPage> getFeed({
    required String? region,
    String? city,
    FeedOrder order = FeedOrder.recent,
    PublicationCategory? category,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await remoteDatasource.getFeed(
      region: region,
      city: city,
      order: order.name,
      category: category != null ? publicationCategoryToString(category) : null,
      page: page,
      limit: limit,
    );
    return FeedPage(
      items: response.items.map((m) => m.toEntity()).toList(),
      page: response.page,
      limit: response.limit,
      total: response.total,
      hasMore: response.hasMore,
      currentRegion: region,
      currentCity: city,
      currentCategory: category,
      currentOrder: order,
    );
  }

  @override
  Future<GeoLocation> detectRegion() async {
    final geo = await geoDatasource.getCurrentLocation();
    if (geo.region.isNotEmpty) {
      await storage.write(StorageKeys.region, geo.region);
    }
    // La ciudad viaja junto a la región en el reverse geocoding; se cachea
    // para pre-llenar formularios (p. ej. crear publicación).
    final city = geo.city;
    if (city != null && city.isNotEmpty) {
      await storage.write(StorageKeys.city, city);
    }
    return geo;
  }
}
