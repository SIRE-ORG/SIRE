import '../../domain/entities/availability_config.dart';
import '../../domain/entities/publication.dart';
import 'publication_detail_model.dart';

class CreatePublicationRequestModel {
  const CreatePublicationRequestModel({
    required this.title,
    required this.description,
    required this.category,
    this.imageUrl,
    required this.region,
    this.city,
    required this.availability,
  });

  final String title;
  final String description;
  final PublicationCategory category;
  final String? imageUrl;
  final String region;
  final String? city;
  final AvailabilityConfig availability;

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'category': publicationCategoryToString(category),
    'imageUrl': imageUrl,
    'region': region,
    'city': ?city,
    'availability': AvailabilityConfigModel.fromEntity(availability).toJson(),
  };
}
