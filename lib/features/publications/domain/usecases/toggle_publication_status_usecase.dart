import '../repositories/publications_repository.dart';

class TogglePublicationStatusUseCase {
  const TogglePublicationStatusUseCase(this._repository);

  final PublicationsRepository _repository;

  Future<void> call({required String id, required bool isActive}) =>
      _repository.togglePublicationStatus(id: id, isActive: isActive);
}
