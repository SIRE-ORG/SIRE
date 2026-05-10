import 'publication_summary_model.dart';

class FeedResponseModel {
  const FeedResponseModel({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.hasMore,
  });

  final List<PublicationSummaryModel> items;
  final int page;
  final int limit;
  final int total;
  final bool hasMore;

  factory FeedResponseModel.fromJson(Map<String, dynamic> json) {
    final pagination = ((json['pagination'] as Map?) ?? const {})
        .cast<String, dynamic>();
    final data = (json['data'] as List?) ?? const [];
    return FeedResponseModel(
      items: data
          .map(
            (e) => PublicationSummaryModel.fromJson(
              (e as Map).cast<String, dynamic>(),
            ),
          )
          .toList(),
      page: pagination['page'] as int? ?? 1,
      limit: pagination['limit'] as int? ?? 20,
      total: pagination['total'] as int? ?? 0,
      hasMore: pagination['hasMore'] as bool? ?? false,
    );
  }
}
