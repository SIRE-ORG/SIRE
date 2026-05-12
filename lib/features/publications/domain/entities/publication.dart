import 'package:equatable/equatable.dart';

import 'availability_config.dart';

enum PublicationCategory { deporte, eventos, recreacion, otros }

class Publication extends Equatable {
  const Publication({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.region,
    this.city,
    required this.category,
    required this.ownerId,
    required this.ownerName,
    this.rating,
    required this.isActive,
    required this.availability,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final String region;
  final String? city;
  final PublicationCategory category;
  final String ownerId;
  final String ownerName;
  final double? rating;
  final bool isActive;
  final AvailabilityConfig availability;
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
    ownerId,
    ownerName,
    rating,
    isActive,
    availability,
    createdAt,
  ];
}
