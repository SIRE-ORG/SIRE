import '../../domain/entities/availability_config.dart';
import '../../domain/entities/publication.dart';
import 'publication_detail_model.dart';

class UpdatePublicationRequestModel {
  const UpdatePublicationRequestModel({
    this.title,
    this.description,
    this.category,
    this.imageUrl,
    this.region,
    this.city,
    this.availability,
  });

  final String? title;
  final String? description;
  final PublicationCategory? category;
  final String? imageUrl;
  final String? region;
  final String? city;
  final AvailabilityConfig? availability;

  Map<String, dynamic> toJson() => {
    'title': ?title,
    'description': ?description,
    if (category != null) 'category': publicationCategoryToString(category!),
    'imageUrl': ?imageUrl,
    'region': ?region,
    'city': ?city,
    if (availability != null)
      'availability': AvailabilityConfigModel.fromEntity(
        availability!,
      ).toJson(),
  };
}
