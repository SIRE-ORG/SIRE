import '../entities/availability_config.dart';
import '../entities/publication.dart';
import '../entities/publication_summary_item.dart';

class MyPublicationsResult {
  const MyPublicationsResult({
    required this.items,
    required this.page,
    required this.hasMore,
    required this.total,
  });

  final List<PublicationSummaryItem> items;
  final int page;
  final bool hasMore;
  final int total;
}

abstract interface class PublicationsRepository {
  Future<Publication> getPublicationDetail({required String id});

  Future<MyPublicationsResult> getMyPublications({
    int page = 1,
    int limit = 20,
  });

  Future<Publication> createPublication({
    required String title,
    required String description,
    required PublicationCategory category,
    String? imageUrl,
    required String region,
    String? city,
    required AvailabilityConfig availability,
  });

  Future<Publication> updatePublication({
    required String id,
    String? title,
    String? description,
    PublicationCategory? category,
    String? imageUrl,
    String? region,
    String? city,
    AvailabilityConfig? availability,
  });

  Future<void> togglePublicationStatus({
    required String id,
    required bool isActive,
  });

  Future<void> deletePublication({required String id});
}
