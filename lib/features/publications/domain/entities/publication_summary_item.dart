import 'package:equatable/equatable.dart';

import 'publication.dart';

class PublicationSummaryItem extends Equatable {
  const PublicationSummaryItem({
    required this.id,
    required this.title,
    this.imageUrl,
    required this.category,
    required this.region,
    required this.isActive,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String? imageUrl;
  final PublicationCategory category;
  final String region;
  final bool isActive;
  final String createdAt;

  @override
  List<Object?> get props => [
    id,
    title,
    imageUrl,
    category,
    region,
    isActive,
    createdAt,
  ];
}
