import '../../../publications/data/models/publication_detail_model.dart';
import '../../domain/entities/publication_summary.dart';

class PublicationSummaryModel {
  const PublicationSummaryModel({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.region,
    this.city,
    required this.category,
    required this.ownerName,
    required this.ownerId,
    this.rating,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final String region;
  final String? city;
  final String category;
  final String ownerName;
  final String ownerId;
  final double? rating;
  final String createdAt;

  factory PublicationSummaryModel.fromJson(Map<String, dynamic> json) {
    return PublicationSummaryModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      region: json['region'] as String? ?? '',
      city: json['city'] as String?,
      category: json['category'] as String? ?? 'OTROS',
      ownerName: json['ownerName'] as String? ?? '',
      ownerId: json['ownerId'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble(),
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  PublicationSummary toEntity() => PublicationSummary(
    id: id,
    title: title,
    description: description,
    imageUrl: imageUrl,
    region: region,
    city: city,
    category: publicationCategoryFromString(category),
    ownerName: ownerName,
    ownerId: ownerId,
    rating: rating,
    createdAt: createdAt,
  );
}
