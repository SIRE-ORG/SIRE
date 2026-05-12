import '../../domain/entities/publication_summary_item.dart';
import 'publication_detail_model.dart';

class PublicationSummaryItemModel {
  const PublicationSummaryItemModel({
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
  final String category;
  final String region;
  final bool isActive;
  final String createdAt;

  factory PublicationSummaryItemModel.fromJson(Map<String, dynamic> json) {
    return PublicationSummaryItemModel(
      id: json['id'] as String,
      title: json['title'] as String,
      imageUrl: json['imageUrl'] as String?,
      category: json['category'] as String? ?? 'OTROS',
      region: json['region'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  PublicationSummaryItem toEntity() => PublicationSummaryItem(
    id: id,
    title: title,
    imageUrl: imageUrl,
    category: publicationCategoryFromString(category),
    region: region,
    isActive: isActive,
    createdAt: createdAt,
  );
}
