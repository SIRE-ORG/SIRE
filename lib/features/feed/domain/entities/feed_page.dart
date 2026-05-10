import 'package:equatable/equatable.dart';

import '../../../publications/domain/entities/publication.dart';
import 'publication_summary.dart';

enum FeedOrder { recent, rating, popular }

class FeedPage extends Equatable {
  const FeedPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.hasMore,
    required this.currentRegion,
    this.currentCity,
    this.currentCategory,
    required this.currentOrder,
  });

  final List<PublicationSummary> items;
  final int page;
  final int limit;
  final int total;
  final bool hasMore;
  final String currentRegion;
  final String? currentCity;
  final PublicationCategory? currentCategory;
  final FeedOrder currentOrder;

  FeedPage copyWith({
    List<PublicationSummary>? items,
    int? page,
    int? limit,
    int? total,
    bool? hasMore,
    String? currentRegion,
    String? currentCity,
    PublicationCategory? currentCategory,
    bool clearCategory = false,
    FeedOrder? currentOrder,
  }) {
    return FeedPage(
      items: items ?? this.items,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      total: total ?? this.total,
      hasMore: hasMore ?? this.hasMore,
      currentRegion: currentRegion ?? this.currentRegion,
      currentCity: currentCity ?? this.currentCity,
      currentCategory: clearCategory
          ? null
          : (currentCategory ?? this.currentCategory),
      currentOrder: currentOrder ?? this.currentOrder,
    );
  }

  @override
  List<Object?> get props => [
    items,
    page,
    limit,
    total,
    hasMore,
    currentRegion,
    currentCity,
    currentCategory,
    currentOrder,
  ];
}
