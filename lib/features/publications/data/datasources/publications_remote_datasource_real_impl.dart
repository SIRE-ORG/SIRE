import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/api_constants.dart';
import '../../../../core/network/app_exception.dart';
import '../models/create_publication_request_model.dart';
import '../models/publication_detail_model.dart';
import '../models/publication_summary_item_model.dart';
import '../models/update_publication_request_model.dart';
import 'publications_remote_datasource.dart';

/// Implementación real de [PublicationsRemoteDatasource] contra el backend local.
///
/// Endpoints disponibles (backend v0, post-merge cristian/endpoint-auth):
///   GET  /publications/publications/mine  → [getMyPublications]
///   POST /publications/publications        → [createPublication]
///
/// Métodos no disponibles aún (lanzan [ServerException] ENDPOINT_NOT_AVAILABLE):
///   getPublicationDetail, updatePublication, togglePublicationStatus, deletePublication
///
/// Auth: el [_AuthInterceptor] de [DioClient] inyecta automáticamente
/// x-user-id desde la sesión Supabase, que es el mecanismo que usa el backend.
///
/// PATH: usa [ApiConstants.publicationsFeedMineLive] / [publicationsFeedLive]
/// por el bug de double-segment documentado en claude/comentarios_backend.txt C.
class PublicationsRemoteDatasourceRealImpl
    implements PublicationsRemoteDatasource {
  const PublicationsRemoteDatasourceRealImpl({
    required this.dio,
    required this.supabase,
  });

  final Dio dio;
  final SupabaseClient supabase;

  @override
  Future<MyPublicationsResponse> getMyPublications({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await dio.get(ApiConstants.publicationsFeedMineLive);
    final raw =
        ((response.data as Map<String, dynamic>)['data'] as List?) ?? [];
    final items = raw
        .cast<Map<String, dynamic>>()
        .map(PublicationSummaryItemModel.fromJson)
        .toList();
    return MyPublicationsResponse(
      items: items,
      page: 1,
      limit: items.length,
      total: items.length,
      hasMore: false,
    );
  }

  @override
  Future<PublicationDetailModel> createPublication({
    required CreatePublicationRequestModel body,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw UnauthorizedException();

    final payload = {...body.toJson(), 'ownerId': user.id};
    final response = await dio.post(
      ApiConstants.publicationsFeedLive,
      data: payload,
    );
    final json =
        (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return _mapToDetail(json);
  }

  @override
  Future<PublicationDetailModel> getPublicationDetail({required String id}) {
    throw ServerException(
      code: 'ENDPOINT_NOT_AVAILABLE',
      message: 'GET /publications/:id no implementado en el backend',
    );
  }

  @override
  Future<PublicationDetailModel> updatePublication({
    required String id,
    required UpdatePublicationRequestModel body,
  }) {
    throw ServerException(
      code: 'ENDPOINT_NOT_AVAILABLE',
      message: 'PUT /publications/:id no implementado en el backend',
    );
  }

  @override
  Future<void> togglePublicationStatus({
    required String id,
    required bool isActive,
  }) {
    throw ServerException(
      code: 'ENDPOINT_NOT_AVAILABLE',
      message: 'PATCH /publications/:id/status no implementado en el backend',
    );
  }

  @override
  Future<void> deletePublication({required String id}) {
    throw ServerException(
      code: 'ENDPOINT_NOT_AVAILABLE',
      message: 'DELETE /publications/:id no implementado en el backend',
    );
  }

  PublicationDetailModel _mapToDetail(Map<String, dynamic> json) {
    return PublicationDetailModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      region: json['region'] as String? ?? '',
      city: json['city'] as String?,
      category: json['category'] as String? ?? 'OTROS',
      ownerId: json['ownerId'] as String? ?? '',
      ownerName: '',
      rating: null,
      isActive: json['isActive'] as bool? ?? true,
      availability: AvailabilityConfigModel.fromJson(
        (json['availability'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}
