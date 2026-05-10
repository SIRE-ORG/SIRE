import '../entities/feed_page.dart';
import '../repositories/feed_repository.dart';

class LoadMoreFeedUseCase {
  const LoadMoreFeedUseCase(this._repository);

  final FeedRepository _repository;

  Future<FeedPage> call({required FeedPage currentPage}) async {
    if (!currentPage.hasMore) return currentPage;
    final nextPage = await _repository.getFeed(
      region: currentPage.currentRegion,
      city: currentPage.currentCity,
      order: currentPage.currentOrder,
      category: currentPage.currentCategory,
      page: currentPage.page + 1,
      limit: currentPage.limit,
    );
    return nextPage.copyWith(items: [...currentPage.items, ...nextPage.items]);
  }
}
