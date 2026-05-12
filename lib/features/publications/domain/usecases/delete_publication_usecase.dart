import '../repositories/publications_repository.dart';

class DeletePublicationUseCase {
  const DeletePublicationUseCase(this._repository);

  final PublicationsRepository _repository;

  Future<void> call({required String id}) =>
      _repository.deletePublication(id: id);
}
