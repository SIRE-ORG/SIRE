import '../repositories/notifications_repository.dart';

class MarkNotificationReadUseCase {
  const MarkNotificationReadUseCase(this._repository);

  final NotificationsRepository _repository;

  Future<void> call({required String id}) => _repository.markAsRead(id);
}
