import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:sire/features/feed/domain/entities/feed_page.dart';
import 'package:sire/features/feed/domain/repositories/feed_repository.dart';
import 'package:sire/features/feed/domain/usecases/get_feed_usecase.dart';
import 'package:sire/features/feed/domain/usecases/load_more_feed_usecase.dart';
import 'package:sire/features/publications/domain/entities/publication.dart';

class _MockFeedRepository extends Mock implements FeedRepository {}

final _kPage1 = FeedPage(
  items: const [],
  page: 1,
  limit: 20,
  total: 40,
  hasMore: true,
  currentRegion: 'Temuco',
  currentOrder: FeedOrder.recent,
);

final _kPage2 = FeedPage(
  items: const [],
  page: 2,
  limit: 20,
  total: 40,
  hasMore: false,
  currentRegion: 'Temuco',
  currentOrder: FeedOrder.recent,
);

void main() {
  late _MockFeedRepository repo;

  setUp(() {
    repo = _MockFeedRepository();
    registerFallbackValue(FeedOrder.recent);
    registerFallbackValue(PublicationCategory.deporte);
  });

  group('GetFeedUseCase', () {
    test('delega al repositorio y retorna FeedPage', () async {
      when(() => repo.getFeed(
            region: any(named: 'region'),
            city: any(named: 'city'),
            order: any(named: 'order'),
            category: any(named: 'category'),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => _kPage1);

      final result = await GetFeedUseCase(repo).call(region: 'Temuco');

      expect(result.currentRegion, equals('Temuco'));
      expect(result.page, equals(1));
    });

    test('retorna página con hasMore true cuando hay más resultados', () async {
      when(() => repo.getFeed(
            region: any(named: 'region'),
            city: any(named: 'city'),
            order: any(named: 'order'),
            category: any(named: 'category'),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => _kPage1);

      final result = await GetFeedUseCase(repo).call(region: 'Temuco');

      expect(result.hasMore, isTrue);
    });
  });

  group('LoadMoreFeedUseCase', () {
    test('retorna la misma página si hasMore es false', () async {
      final pageNoMore = _kPage1.copyWith(hasMore: false);

      final result =
          await LoadMoreFeedUseCase(repo).call(currentPage: pageNoMore);

      expect(result, equals(pageNoMore));
      verifyNever(() => repo.getFeed(
            region: any(named: 'region'),
            city: any(named: 'city'),
            order: any(named: 'order'),
            category: any(named: 'category'),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          ));
    });

    test('carga página siguiente y concatena items cuando hasMore es true',
        () async {
      when(() => repo.getFeed(
            region: any(named: 'region'),
            city: any(named: 'city'),
            order: any(named: 'order'),
            category: any(named: 'category'),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => _kPage2);

      final result =
          await LoadMoreFeedUseCase(repo).call(currentPage: _kPage1);

      expect(result.page, equals(2));
      expect(result.hasMore, isFalse);
    });
  });
}
