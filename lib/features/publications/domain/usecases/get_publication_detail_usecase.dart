import '../entities/publication.dart';
import '../repositories/publications_repository.dart';

class GetPublicationDetailUseCase {
  const GetPublicationDetailUseCase(this._repository);

  final PublicationsRepository _repository;

  Future<Publication> call({required String id}) =>
      _repository.getPublicationDetail(id: id);
}
