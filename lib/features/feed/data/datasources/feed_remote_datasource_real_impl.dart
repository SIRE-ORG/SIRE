import 'package:dio/dio.dart';

import '../../../../core/network/api_constants.dart';
import '../models/feed_response_model.dart';
import '../models/publication_summary_model.dart';
import 'feed_remote_datasource.dart';

/// Implementación real de [FeedRemoteDatasource] contra el backend local.
///
/// LIMITACIÓN: El backend no implementa paginación ni los filtros city/order.
/// Solo acepta el filtro `region`. Los demás parámetros se ignoran hasta que
/// el backend implemente GET /feed con soporte completo.
///
/// PATH: usa [ApiConstants.publicationsFeedLive] (/publications/publications)
/// por el bug de double-segment documentado en claude/comentarios_backend.txt C.
class FeedRemoteDatasourceRealImpl implements FeedRemoteDatasource {
  const FeedRemoteDatasourceRealImpl({required this.dio});

  final Dio dio;

  @override
  Future<FeedResponseModel> getFeed({
    required String? region,
    String? city,
    String? order,
    String? category,
    int page = 1,
    int limit = 20,
  }) async {
    var items = await _fetch(region);
    // Si filtrar por región no devuelve nada (los strings de región del
    // dispositivo/Nominatim no calzan con los del backend), se reintenta SIN
    // filtro para no dejar el feed vacío. El filtrado fino por región queda
    // pendiente del normalizador. Con region null ("Todas las regiones") la
    // primera petición ya va sin filtro, así que no hay reintento posible.
    if (items.isEmpty && region != null && region.isNotEmpty) {
      items = await _fetch(null);
    }

    return FeedResponseModel(
      items: items,
      page: 1,
      limit: items.length,
      total: items.length,
      hasMore: false,
    );
  }

  Future<List<PublicationSummaryModel>> _fetch(String? region) async {
    final response = await dio.get(
      ApiConstants.publicationsFeedLive,
      queryParameters: {
        if (region != null && region.isNotEmpty) 'region': region,
      },
    );
    final raw =
        ((response.data as Map<String, dynamic>)['data'] as List?) ?? [];
    return raw.cast<Map<String, dynamic>>().map(_mapToSummary).toList();
  }

  PublicationSummaryModel _mapToSummary(Map<String, dynamic> json) {
    final owner = (json['owner'] as Map?)?.cast<String, dynamic>() ?? const {};
    return PublicationSummaryModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      region: json['region'] as String? ?? '',
      city: json['city'] as String?,
      category: json['category'] as String? ?? 'OTROS',
      ownerName: owner['name'] as String? ?? '',
      ownerId: json['ownerId'] as String? ?? '',
      rating: null,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}
