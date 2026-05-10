import 'dart:typed_data';

import '../../data/datasources/publication_image_datasource.dart';
import '../entities/availability_config.dart';
import '../entities/publication.dart';
import '../repositories/publications_repository.dart';

class UpdatePublicationParams {
  const UpdatePublicationParams({
    this.title,
    this.description,
    this.category,
    this.region,
    this.city,
    this.availability,
  });

  final String? title;
  final String? description;
  final PublicationCategory? category;
  final String? region;
  final String? city;
  final AvailabilityConfig? availability;
}

class UpdatePublicationUseCase {
  const UpdatePublicationUseCase({
    required PublicationsRepository repository,
    required PublicationImageDatasource imageDatasource,
  }) : _repository = repository,
       _imageDatasource = imageDatasource;

  final PublicationsRepository _repository;
  final PublicationImageDatasource _imageDatasource;

  Future<Publication> call({
    required String id,
    required UpdatePublicationParams params,
    Uint8List? imageBytes,
    String? imageExtension,
  }) async {
    String? imageUrl;
    if (imageBytes != null) {
      imageUrl = await _imageDatasource.uploadImage(
        bytes: imageBytes,
        extension: imageExtension ?? 'jpg',
      );
    }
    return _repository.updatePublication(
      id: id,
      title: params.title,
      description: params.description,
      category: params.category,
      imageUrl: imageUrl,
      region: params.region,
      city: params.city,
      availability: params.availability,
    );
  }
}
