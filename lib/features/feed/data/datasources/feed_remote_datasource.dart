import '../models/feed_response_model.dart';

abstract interface class FeedRemoteDatasource {
  Future<FeedResponseModel> getFeed({
    required String region,
    String? city,
    String? order,
    String? category,
    int page = 1,
    int limit = 20,
  });
}
