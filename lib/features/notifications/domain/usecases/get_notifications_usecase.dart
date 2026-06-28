import '../entities/app_notification.dart';
import '../repositories/notifications_repository.dart';

class GetNotificationsUseCase {
  const GetNotificationsUseCase(this._repository);

  final NotificationsRepository _repository;

  Future<List<AppNotification>> call({
    bool unreadOnly = false,
    int page = 1,
    int limit = 20,
  }) => _repository.getNotifications(
    unreadOnly: unreadOnly,
    page: page,
    limit: limit,
  );
}
