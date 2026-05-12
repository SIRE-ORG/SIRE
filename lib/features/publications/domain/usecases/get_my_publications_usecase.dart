import '../repositories/publications_repository.dart';

class GetMyPublicationsUseCase {
  const GetMyPublicationsUseCase(this._repository);

  final PublicationsRepository _repository;

  Future<MyPublicationsResult> call({int page = 1, int limit = 20}) =>
      _repository.getMyPublications(page: page, limit: limit);
}
