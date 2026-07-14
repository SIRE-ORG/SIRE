import '../../../publications/domain/entities/publication.dart';
import '../entities/feed_page.dart';
import '../entities/geo_location.dart';

abstract interface class FeedRepository {
  /// [region] null: sin filtro de región ("Todas las regiones").
  Future<FeedPage> getFeed({
    required String? region,
    String? city,
    FeedOrder order = FeedOrder.recent,
    PublicationCategory? category,
    int page = 1,
    int limit = 20,
  });

  Future<GeoLocation> detectRegion();
}
