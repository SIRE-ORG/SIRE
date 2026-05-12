import 'package:equatable/equatable.dart';

import '../../../publications/domain/entities/publication.dart';

class PublicationSummary extends Equatable {
  const PublicationSummary({
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
  final PublicationCategory category;
  final String ownerName;
  final String ownerId;
  final double? rating;
  final String createdAt;

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    imageUrl,
    region,
    city,
    category,
    ownerName,
    ownerId,
    rating,
    createdAt,
  ];
}
