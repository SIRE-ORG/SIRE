import 'package:dio/dio.dart';

import '../../../../core/network/api_constants.dart';
import '../models/feed_response_model.dart';
import 'feed_remote_datasource.dart';

class FeedRemoteDatasourceImpl implements FeedRemoteDatasource {
  const FeedRemoteDatasourceImpl({required this.dio});

  final Dio dio;

  @override
  Future<FeedResponseModel> getFeed({
    required String region,
    String? city,
    String? order,
    String? category,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await dio.get(
      ApiConstants.feed,
      queryParameters: {
        'region': region,
        'city': ?city,
        'order': ?order,
        'category': ?category,
        'page': page,
        'limit': limit,
      },
    );
    return FeedResponseModel.fromJson(
      (response.data as Map).cast<String, dynamic>(),
    );
  }
}
