import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_datasource.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  const NotificationsRepositoryImpl({required this.datasource});

  final NotificationsDatasource datasource;

  @override
  Future<List<AppNotification>> getNotifications({
    bool unreadOnly = false,
    int page = 1,
    int limit = 20,
  }) async {
    final models = await datasource.getNotifications(
      unreadOnly: unreadOnly,
      page: page,
      limit: limit,
    );
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Stream<List<AppNotification>> watchNotifications() => datasource
      .watchNotifications()
      .map((models) => models.map((m) => m.toEntity()).toList());

  @override
  Future<void> markAsRead(String id) => datasource.markAsRead(id);

  @override
  Future<void> markAllAsRead() => datasource.markAllAsRead();
}
