import '../models/notification_model.dart';

abstract interface class NotificationsDatasource {
  Future<List<NotificationModel>> getNotifications({
    bool unreadOnly = false,
    int page = 1,
    int limit = 20,
  });

  Stream<List<NotificationModel>> watchNotifications();

  Future<void> markAsRead(String id);

  Future<void> markAllAsRead();
}
