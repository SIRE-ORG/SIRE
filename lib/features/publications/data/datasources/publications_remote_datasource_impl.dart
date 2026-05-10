import 'package:dio/dio.dart';

import '../../../../core/network/api_constants.dart';
import '../models/create_publication_request_model.dart';
import '../models/publication_detail_model.dart';
import '../models/publication_status_update_model.dart';
import '../models/publication_summary_item_model.dart';
import '../models/update_publication_request_model.dart';
import 'publications_remote_datasource.dart';

class PublicationsRemoteDatasourceImpl implements PublicationsRemoteDatasource {
  const PublicationsRemoteDatasourceImpl({required this.dio});

  final Dio dio;

  @override
  Future<PublicationDetailModel> getPublicationDetail({
    required String id,
  }) async {
    final response = await dio.get('${ApiConstants.publications}/$id');
    return PublicationDetailModel.fromJson(
      (response.data as Map).cast<String, dynamic>(),
    );
  }

  @override
  Future<MyPublicationsResponse> getMyPublications({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await dio.get(
      ApiConstants.publicationsMine,
      queryParameters: {'page': page, 'limit': limit},
    );
    final data = (response.data as Map).cast<String, dynamic>();
    final pagination = (data['pagination'] as Map).cast<String, dynamic>();
    final items = (data['data'] as List)
        .map(
          (e) => PublicationSummaryItemModel.fromJson(
            (e as Map).cast<String, dynamic>(),
          ),
        )
        .toList();
    return MyPublicationsResponse(
      items: items,
      page: pagination['page'] as int,
      limit: pagination['limit'] as int,
      total: pagination['total'] as int,
      hasMore: pagination['hasMore'] as bool,
    );
  }

  @override
  Future<PublicationDetailModel> createPublication({
    required CreatePublicationRequestModel body,
  }) async {
    final created = await dio.post(
      ApiConstants.publications,
      data: body.toJson(),
    );
    final createdData = (created.data as Map).cast<String, dynamic>();
    final id = createdData['id'] as String;
    return getPublicationDetail(id: id);
  }

  @override
  Future<PublicationDetailModel> updatePublication({
    required String id,
    required UpdatePublicationRequestModel body,
  }) async {
    await dio.put('${ApiConstants.publications}/$id', data: body.toJson());
    return getPublicationDetail(id: id);
  }

  @override
  Future<void> togglePublicationStatus({
    required String id,
    required bool isActive,
  }) async {
    await dio.patch(
      '${ApiConstants.publications}/$id/status',
      data: PublicationStatusUpdateModel(isActive: isActive).toJson(),
    );
  }

  @override
  Future<void> deletePublication({required String id}) async {
    await dio.delete('${ApiConstants.publications}/$id');
  }
}
