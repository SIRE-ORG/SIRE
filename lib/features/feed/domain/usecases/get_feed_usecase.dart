import '../../../publications/domain/entities/publication.dart';
import '../entities/feed_page.dart';
import '../repositories/feed_repository.dart';

class GetFeedUseCase {
  const GetFeedUseCase(this._repository);

  final FeedRepository _repository;

  /// [region] null: sin filtro de región ("Todas las regiones").
  Future<FeedPage> call({
    required String? region,
    String? city,
    FeedOrder order = FeedOrder.recent,
    PublicationCategory? category,
    int page = 1,
    int limit = 20,
  }) => _repository.getFeed(
    region: region,
    city: city,
    order: order,
    category: category,
    page: page,
    limit: limit,
  );
}
