import '../../domain/entities/availability_config.dart';
import '../../domain/entities/publication.dart';
import '../../domain/repositories/publications_repository.dart';
import '../datasources/publications_remote_datasource.dart';
import '../models/create_publication_request_model.dart';
import '../models/update_publication_request_model.dart';

class PublicationsRepositoryImpl implements PublicationsRepository {
  const PublicationsRepositoryImpl({required this.remoteDatasource});

  final PublicationsRemoteDatasource remoteDatasource;

  @override
  Future<Publication> getPublicationDetail({required String id}) async {
    final model = await remoteDatasource.getPublicationDetail(id: id);
    return model.toEntity();
  }

  @override
  Future<MyPublicationsResult> getMyPublications({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await remoteDatasource.getMyPublications(
      page: page,
      limit: limit,
    );
    return MyPublicationsResult(
      items: response.items.map((m) => m.toEntity()).toList(),
      page: response.page,
      hasMore: response.hasMore,
      total: response.total,
    );
  }

  @override
  Future<Publication> createPublication({
    required String title,
    required String description,
    required PublicationCategory category,
    String? imageUrl,
    required String region,
    String? city,
    required AvailabilityConfig availability,
  }) async {
    final body = CreatePublicationRequestModel(
      title: title,
      description: description,
      category: category,
      imageUrl: imageUrl,
      region: region,
      city: city,
      availability: availability,
    );
    final model = await remoteDatasource.createPublication(body: body);
    return model.toEntity();
  }

  @override
  Future<Publication> updatePublication({
    required String id,
    String? title,
    String? description,
    PublicationCategory? category,
    String? imageUrl,
    String? region,
    String? city,
    AvailabilityConfig? availability,
  }) async {
    final body = UpdatePublicationRequestModel(
      title: title,
      description: description,
      category: category,
      imageUrl: imageUrl,
      region: region,
      city: city,
      availability: availability,
    );
    final model = await remoteDatasource.updatePublication(id: id, body: body);
    return model.toEntity();
  }

  @override
  Future<void> togglePublicationStatus({
    required String id,
    required bool isActive,
  }) => remoteDatasource.togglePublicationStatus(id: id, isActive: isActive);

  @override
  Future<void> deletePublication({required String id}) =>
      remoteDatasource.deletePublication(id: id);
}
