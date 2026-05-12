import '../models/create_publication_request_model.dart';
import '../models/publication_detail_model.dart';
import '../models/publication_summary_item_model.dart';
import '../models/update_publication_request_model.dart';

class MyPublicationsResponse {
  const MyPublicationsResponse({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.hasMore,
  });

  final List<PublicationSummaryItemModel> items;
  final int page;
  final int limit;
  final int total;
  final bool hasMore;
}

abstract interface class PublicationsRemoteDatasource {
  Future<PublicationDetailModel> getPublicationDetail({required String id});

  Future<MyPublicationsResponse> getMyPublications({
    int page = 1,
    int limit = 20,
  });

  Future<PublicationDetailModel> createPublication({
    required CreatePublicationRequestModel body,
  });

  Future<PublicationDetailModel> updatePublication({
    required String id,
    required UpdatePublicationRequestModel body,
  });

  Future<void> togglePublicationStatus({
    required String id,
    required bool isActive,
  });

  Future<void> deletePublication({required String id});
}
