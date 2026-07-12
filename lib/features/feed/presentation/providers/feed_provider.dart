import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/api_flags.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../publications/domain/entities/publication.dart';
import '../../data/datasources/feed_remote_datasource.dart';
import '../../data/datasources/feed_remote_datasource_mock_impl.dart';
import '../../data/datasources/feed_remote_datasource_real_impl.dart';
import '../../data/datasources/geo_datasource.dart';
import '../../data/datasources/geo_datasource_impl.dart';
import '../../data/datasources/nominatim_reverse_geocoding_datasource_impl.dart';
import '../../data/repositories/feed_repository_impl.dart';
import '../../domain/entities/feed_page.dart';
import '../../domain/repositories/feed_repository.dart';
import '../../domain/usecases/detect_region_usecase.dart';
import '../../domain/usecases/get_feed_usecase.dart';
import '../../domain/usecases/load_more_feed_usecase.dart';

part 'feed_provider.g.dart';

// ---------------------------------------------------------------------------
// Infraestructura
// ---------------------------------------------------------------------------

@riverpod
FeedRemoteDatasource feedRemoteDatasource(Ref ref) => ApiFlags.useMocks
    ? const FeedRemoteDatasourceMockImpl()
    : FeedRemoteDatasourceRealImpl(dio: DioClient.createSync().dio);

@riverpod
GeoDatasource geoDatasource(Ref ref) => GeoDatasourceImpl(
  reverseGeocoder: NominatimReverseGeocodingDatasourceImpl(),
);

@riverpod
FeedRepository feedRepository(Ref ref) => FeedRepositoryImpl(
  remoteDatasource: ref.watch(feedRemoteDatasourceProvider),
  geoDatasource: ref.watch(geoDatasourceProvider),
  storage: const LocalStorageService(),
);

// ---------------------------------------------------------------------------
// FeedNotifier — feed paginado con geo-detección y filtros
// ---------------------------------------------------------------------------

@riverpod
class FeedNotifier extends _$FeedNotifier {
  @override
  Future<FeedPage> build() async {
    final repo = ref.read(feedRepositoryProvider);
    final cached = await const LocalStorageService().read(StorageKeys.region);
    final region = (cached != null && cached.isNotEmpty)
        ? cached
        : (await DetectRegionUseCase(repo).call()).region;
    return GetFeedUseCase(repo).call(region: region);
  }

  Future<void> initialize() async {
    ref.invalidateSelf();
    await future;
  }

  Future<void> setRegionManually(String region) async {
    state = const AsyncLoading();
    await const LocalStorageService().write(StorageKeys.region, region);
    state = await AsyncValue.guard(
      () =>
          GetFeedUseCase(ref.read(feedRepositoryProvider)).call(region: region),
    );
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore) return;
    final next = await LoadMoreFeedUseCase(
      ref.read(feedRepositoryProvider),
    ).call(currentPage: current);
    state = AsyncData(next);
  }

  Future<void> setCategory(PublicationCategory? category) async {
    final current = state.value;
    if (current == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => GetFeedUseCase(ref.read(feedRepositoryProvider)).call(
        region: current.currentRegion,
        city: current.currentCity,
        order: current.currentOrder,
        category: category,
      ),
    );
  }

  Future<void> setOrder(FeedOrder order) async {
    final current = state.value;
    if (current == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => GetFeedUseCase(ref.read(feedRepositoryProvider)).call(
        region: current.currentRegion,
        city: current.currentCity,
        order: order,
        category: current.currentCategory,
      ),
    );
  }

  Future<void> refresh() => initialize();
}
