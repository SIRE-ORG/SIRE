import '../models/feed_response_model.dart';

abstract interface class FeedRemoteDatasource {
  /// [region] null: sin filtro de región ("Todas las regiones"); la query
  /// viaja sin el parámetro.
  Future<FeedResponseModel> getFeed({
    required String? region,
    String? city,
    String? order,
    String? category,
    int page = 1,
    int limit = 20,
  });
}
